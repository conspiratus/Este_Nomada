"""
API Views.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.shortcuts import get_object_or_404
from core.models import (
    Story, MenuItem, MenuItemCategory, Settings, Order, OrderItem, InstagramPost, Translation,
    HeroImage, HeroSettings, ContentSection, FooterSection, DeliverySettings,
    Customer, Cart, CartItem, Favorite
)
from .serializers import (
    StorySerializer, MenuItemSerializer, MenuItemCategorySerializer, SettingsSerializer,
    OrderSerializer, InstagramPostSerializer, TranslationSerializer,
    HeroImageSerializer, HeroSettingsSerializer, ContentSectionSerializer,
    FooterSectionSerializer
)


class StoryViewSet(viewsets.ModelViewSet):
    """ViewSet для историй."""
    queryset = Story.objects.filter(published=True)
    serializer_class = StorySerializer
    lookup_field = 'slug'
    
    def get_permissions(self):
        """Разные права доступа для разных действий."""
        if self.action in ['list', 'retrieve', 'public']:
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        """Фильтрация для админки."""
        if self.request.user.is_authenticated:
            return Story.objects.all()
        return Story.objects.filter(published=True)
    
    def get_object(self):
        """Переопределяем для поиска по переведенному slug."""
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field
        slug = self.kwargs[lookup_url_kwarg]
        locale = self.request.query_params.get('locale', 'ru')
        
        # Сначала пытаемся найти по базовому slug
        try:
            story = Story.objects.get(slug=slug, published=True)
            return story
        except Story.DoesNotExist:
            pass
        
        # Если не найдено, ищем по переведенному slug
        try:
            from core.models import StoryTranslation
            translation = StoryTranslation.objects.get(slug=slug, locale=locale)
            return translation.story
        except StoryTranslation.DoesNotExist:
            pass
        
        # Если все еще не найдено, возвращаем 404
        from django.http import Http404
        raise Http404("Story not found")
    
    def get_serializer_context(self):
        """Добавляем request в контекст для сериализатора."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def public(self, request):
        """Публичный список историй."""
        stories = Story.objects.filter(published=True).order_by('-date')
        serializer = self.get_serializer(stories, many=True, context={'request': request})
        return Response(serializer.data)


class MenuItemCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet для категорий блюд."""
    queryset = MenuItemCategory.objects.filter(active=True)
    serializer_class = MenuItemCategorySerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        """Фильтрация для админки."""
        if self.request.user.is_authenticated:
            return MenuItemCategory.objects.all().order_by('order_id')
        return MenuItemCategory.objects.filter(active=True).order_by('order_id')
    
    def get_serializer_context(self):
        """Добавляем request в контекст для сериализатора."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class MenuItemViewSet(viewsets.ModelViewSet):
    """ViewSet для блюд меню."""
    queryset = MenuItem.objects.filter(active=True)
    serializer_class = MenuItemSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        """Фильтрация для админки."""
        if self.request.user.is_authenticated:
            return MenuItem.objects.all()
        return MenuItem.objects.filter(active=True).order_by('order', 'name')
    
    def get_serializer_context(self):
        """Добавляем request в контекст для сериализатора."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def by_category(self, request):
        """Возвращает блюда, сгруппированные по категориям."""
        locale = request.query_params.get('locale', 'ru')
        queryset = self.get_queryset()
        
        # Получаем все активные категории, отсортированные по order_id
        categories = MenuItemCategory.objects.filter(active=True).order_by('order_id')
        
        result = []
        for category in categories:
            # Получаем блюда этой категории
            category_items = queryset.filter(category=category)
            
            if category_items.exists():
                # Получаем перевод категории
                category_translation = category.get_translation(locale)
                
                category_data = {
                    'id': category.id,
                    'order_id': category.order_id,
                    'name': category_translation.name if category_translation else f'Категория #{category.id}',
                    'description': category_translation.description if category_translation else None,
                    'items': MenuItemSerializer(
                        category_items,
                        many=True,
                        context={'request': request}
                    ).data
                }
                result.append(category_data)
        
        # Блюда без категории
        items_without_category = queryset.filter(category__isnull=True)
        if items_without_category.exists():
            result.append({
                'id': None,
                'order_id': 9999,  # Без категории в конце
                'name': 'Другие',
                'description': None,
                'items': MenuItemSerializer(
                    items_without_category,
                    many=True,
                    context={'request': request}
                ).data
            })
        
        return Response(result)


class SettingsViewSet(viewsets.ModelViewSet):
    """ViewSet для настроек."""
    queryset = Settings.objects.all()
    serializer_class = SettingsSerializer
    permission_classes = [IsAuthenticated()]
    
    def get_object(self):
        """Получить единственный экземпляр настроек."""
        return Settings.get_settings()
    
    def list(self, request, *args, **kwargs):
        """Переопределяем list для возврата единственного объекта."""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def public(self, request):
        """Публичные настройки (без секретных данных)."""
        settings = Settings.get_settings()
        serializer = self.get_serializer(settings, context={'request': request})
        # Возвращаем только публичные поля
        data = serializer.data
        return Response({
            'site_name': data.get('site_name'),
            'logo_url': data.get('logo_url'),
            'site_description': data.get('site_description'),
            'contact_email': data.get('contact_email'),
            'telegram_channel': data.get('telegram_channel'),
        })


class OrderViewSet(viewsets.ModelViewSet):
    """ViewSet для заказов."""
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    
    def get_serializer_context(self):
        """Добавляем request в контекст для сериализатора."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_permissions(self):
        """Разные права доступа."""
        if self.action in ['create', 'my_orders']:
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        """Фильтрация заказов."""
        if self.request.user.is_authenticated:
            customer = Customer.objects.filter(user=self.request.user).first()
            if customer:
                return Order.objects.filter(customer=customer).order_by('-created_at')
        return Order.objects.none()
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def my_orders(self, request):
        """Получить заказы текущего пользователя или по email."""
        if request.user.is_authenticated:
            customer = Customer.objects.filter(user=request.user).first()
            if customer:
                orders = Order.objects.filter(customer=customer).order_by('-created_at')
                serializer = self.get_serializer(orders, many=True, context={'request': request})
                return Response(serializer.data)
        
        # Для неавторизованных - поиск по email
        email = request.query_params.get('email')
        if email:
            customer = Customer.objects.filter(email=email).first()
            if customer:
                orders = Order.objects.filter(customer=customer).order_by('-created_at')
                serializer = self.get_serializer(orders, many=True, context={'request': request})
                return Response(serializer.data)
        
        return Response([], status=status.HTTP_200_OK)
    
    def create(self, request, *args, **kwargs):
        """Создание заказа с элементами."""
        data = request.data.copy()
        
        # Валидация обязательных полей
        if not data.get('name'):
            return Response(
                {'error': 'Имя обязательно для заполнения'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if not data.get('email'):
            return Response(
                {'error': 'Email обязателен для заполнения'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if not data.get('phone'):
            return Response(
                {'error': 'Телефон обязателен для заполнения'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Проверяем, есть ли блюда в заказе
        selected_dishes = request.data.get('selected_dishes', [])
        if not selected_dishes:
            return Response(
                {'error': 'Выберите хотя бы одно блюдо'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Проверка для доставки (если не самовывоз)
        is_pickup = data.get('is_pickup', False)
        if not is_pickup:
            if not data.get('postal_code'):
                return Response(
                    {'error': 'Почтовый индекс обязателен для доставки'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Определяем customer
        customer = None
        if request.user.is_authenticated:
            customer = Customer.objects.filter(user=request.user).first()
        else:
            # Для неавторизованных создаем или находим customer по email
            email = data.get('email')
            phone = data.get('phone')
            if email:
                customer = Customer.objects.filter(email=email).first()
                if not customer:
                    customer = Customer.objects.create(
                        email=email,
                        phone=phone or '',
                        name=data.get('name', ''),
                        is_registered=False,
                        email_verified=False
                    )
        
        if customer:
            data['customer'] = customer.id
        
        # Удаляем selected_dishes из data, так как это не поле модели
        data_for_serializer = data.copy()
        if 'selected_dishes' in data_for_serializer:
            del data_for_serializer['selected_dishes']
        
        serializer = self.get_serializer(data=data_for_serializer)
        serializer.is_valid(raise_exception=True)
        order = serializer.save()
        
        # Создаём элементы заказа
        order_total = 0
        
        for dish_data in selected_dishes:
            # Поддерживаем оба формата: список ID и список словарей
            if isinstance(dish_data, dict):
                menu_item_id = dish_data.get('menu_item_id') or dish_data.get('id')
                quantity = int(dish_data.get('quantity', 1))
            else:
                # Старый формат: просто ID
                menu_item_id = dish_data
                quantity = 1
            
            try:
                menu_item = MenuItem.objects.get(id=menu_item_id, active=True)
                OrderItem.objects.create(
                    order=order,
                    menu_item=menu_item,
                    quantity=quantity
                )
                if menu_item.price:
                    order_total += float(menu_item.price) * quantity
            except MenuItem.DoesNotExist:
                pass
        
        # Рассчитываем стоимость доставки только если не самовывоз и указан postal_code
        # КРИТИЧНО: Не делаем расчет доставки синхронно - это может занять 30+ секунд из-за geocoding API
        # Используем значение, которое уже было рассчитано на фронтенде (delivery_cost из запроса)
        # Если не было рассчитано - используем базовую стоимость или 0
        if not is_pickup:
            postal_code = data.get('postal_code')
            delivery_cost_from_request = data.get('delivery_cost', 0)
            
            # Используем стоимость доставки, которая уже была рассчитана на фронтенде
            if delivery_cost_from_request:
                try:
                    order.delivery_cost = float(delivery_cost_from_request)
                    # Если есть расстояние из запроса - сохраняем его
                    if data.get('delivery_distance'):
                        order.delivery_distance = float(data.get('delivery_distance'))
                    # Если есть адрес из запроса - сохраняем его
                    if data.get('address'):
                        order.address = data.get('address')
                    order.save()
                except (ValueError, TypeError):
                    # Если не удалось преобразовать - используем базовую стоимость
                    try:
                        delivery_settings = DeliverySettings.get_settings()
                        order.delivery_cost = float(delivery_settings.base_delivery_cost) if delivery_settings.base_delivery_cost else 0
                        order.save()
                    except:
                        order.delivery_cost = 0
                        order.save()
            else:
                # Если стоимость не была рассчитана - используем базовую
                try:
                    delivery_settings = DeliverySettings.get_settings()
                    order.delivery_cost = float(delivery_settings.base_delivery_cost) if delivery_settings.base_delivery_cost else 0
                    order.save()
                except:
                    order.delivery_cost = 0
                    order.save()
        else:
            # При самовывозе доставка бесплатна
            order.delivery_cost = 0
            order.delivery_distance = None
            order.save()
        
        # Здесь будет обработка через OpenAI (в задаче Celery)
        # КРИТИЧНО: Делаем вызов полностью неблокирующим - не ждем подключения к Redis
        # Запускаем в отдельном потоке с таймаутом, чтобы не блокировать ответ клиенту
        import threading
        import logging
        logger = logging.getLogger(__name__)
        
        def queue_ai_task():
            """Запускаем задачу Celery в отдельном потоке, чтобы не блокировать ответ."""
            try:
                from .tasks import process_order_with_ai
                # Пытаемся подключиться к Celery, но с таймаутом
                # Если Redis недоступен, это не должно блокировать создание ордера
                try:
                    process_order_with_ai.apply_async(
                        args=[order.id],
                        ignore_result=True,
                        expires=300  # Задача истечет через 5 минут, если не выполнится
                    )
                    logger.info(f"AI task queued for order {order.id}")
                except Exception as celery_error:
                    # Если не удалось подключиться к Redis/Celery - это не критично
                    logger.warning(f"Could not queue Celery task for order {order.id}: {str(celery_error)}")
            except ImportError:
                # Если tasks не импортируется - это нормально, Celery может быть не настроен
                logger.debug(f"Celery tasks not available for order {order.id}")
            except Exception as e:
                # Любая другая ошибка - логируем, но не прерываем создание ордера
                logger.warning(f"Unexpected error queuing Celery task for order {order.id}: {str(e)}")
        
        # Запускаем в отдельном потоке (daemon=True - не блокирует завершение процесса)
        thread = threading.Thread(target=queue_ai_task, daemon=True)
        thread.start()
        # НЕ ждем завершения потока - сразу возвращаем ответ клиенту
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class InstagramPostViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet для Instagram постов (только чтение)."""
    queryset = InstagramPost.objects.all()
    serializer_class = InstagramPostSerializer
    permission_classes = [AllowAny()]
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny()])
    def feed(self, request):
        """Лента Instagram постов."""
        posts = InstagramPost.objects.all().order_by('-timestamp')[:20]
        serializer = self.get_serializer(posts, many=True)
        return Response(serializer.data)


class TranslationViewSet(viewsets.ModelViewSet):
    """ViewSet для переводов."""
    queryset = Translation.objects.all()
    serializer_class = TranslationSerializer
    
    def get_permissions(self):
        """Разные права доступа."""
        if self.action in ['list', 'retrieve', 'by_locale']:
            return [AllowAny()]
        return [IsAuthenticated()]
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny()])
    def by_locale(self, request):
        """Получить все переводы для локали в формате для next-intl."""
        locale = request.query_params.get('locale', 'ru')
        translations = Translation.objects.filter(locale=locale)
        
        # Преобразуем в формат next-intl: { namespace: { key: value } }
        result = {}
        for trans in translations:
            if trans.namespace not in result:
                result[trans.namespace] = {}
            result[trans.namespace][trans.key] = trans.value
        
        return Response(result)


class HeroImageViewSet(viewsets.ModelViewSet):
    """ViewSet для Hero изображений."""
    queryset = HeroImage.objects.filter(active=True).order_by('order')
    serializer_class = HeroImageSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        """Фильтрация для админки."""
        if self.request.user.is_authenticated:
            return HeroImage.objects.all().order_by('order')
        return HeroImage.objects.filter(active=True).order_by('order')


class HeroSettingsViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet для настроек Hero (только чтение)."""
    queryset = HeroSettings.objects.all()
    serializer_class = HeroSettingsSerializer
    permission_classes = [AllowAny]
    
    def get_object(self):
        """Всегда возвращаем единственный экземпляр."""
        obj, created = HeroSettings.objects.get_or_create(pk=1, defaults={'slide_interval': 5000})
        return obj
    
    def list(self, request, *args, **kwargs):
        """Переопределяем list для возврата единственного объекта."""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class ContentSectionViewSet(viewsets.ModelViewSet):
    """ViewSet для разделов контента."""
    queryset = ContentSection.objects.filter(published=True).order_by('section_type', 'order')
    serializer_class = ContentSectionSerializer
    permission_classes = [AllowAny]
    lookup_field = 'section_id'
    
    def get_permissions(self):
        """Разные права доступа для разных действий."""
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        """Фильтрация по типу раздела и для админки."""
        queryset = ContentSection.objects.all()
        
        if not (self.request.user.is_authenticated and self.request.user.is_staff):
            # Обычные пользователи видят только опубликованные
            queryset = queryset.filter(published=True)
        
        # Фильтр по типу раздела
        section_type = self.request.query_params.get('section_type', None)
        if section_type:
            queryset = queryset.filter(section_type=section_type)
        
        # Фильтр по конкретному section_id
        section_id = self.request.query_params.get('section_id', None)
        if section_id:
            queryset = queryset.filter(section_id=section_id)
        
        return queryset.order_by('section_type', 'order')


# Для обратной совместимости с about API
class AboutSectionViewSet(ContentSectionViewSet):
    """ViewSet для разделов О нас (алиас для ContentSection с типом 'about')."""
    
    def get_queryset(self):
        """Возвращаем только разделы типа 'about'."""
        queryset = super().get_queryset()
        return queryset.filter(section_type='about')


class FooterSectionViewSet(viewsets.ModelViewSet):
    """ViewSet для секций футера."""
    queryset = FooterSection.objects.filter(published=True).order_by('position', 'order')
    serializer_class = FooterSectionSerializer
    permission_classes = [AllowAny]
    
    def get_permissions(self):
        """Разные права доступа для разных действий."""
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def get_queryset(self):
        """Фильтрация по позиции и для админки."""
        queryset = FooterSection.objects.all()
        
        if not (self.request.user.is_authenticated and self.request.user.is_staff):
            # Обычные пользователи видят только опубликованные
            queryset = queryset.filter(published=True)
        
        # Фильтр по позиции
        position = self.request.query_params.get('position', None)
        if position:
            queryset = queryset.filter(position=position)
        
        return queryset.order_by('position', 'order')
    
    def get_serializer_context(self):
        """Добавляем request в контекст для сериализатора."""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


# ============================================
# ЛИЧНЫЙ КАБИНЕТ И КОРЗИНА
# ============================================

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings as django_settings
import secrets
from .serializers import (
    CustomerSerializer, CartSerializer, CartItemDetailSerializer,
    FavoriteSerializer, DeliverySettingsSerializer
)

User = get_user_model()


class CustomerViewSet(viewsets.ModelViewSet):
    """ViewSet для клиентов."""
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Пользователь видит только свой профиль."""
        if self.request.user.is_staff:
            return Customer.objects.all()
        return Customer.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def register(self, request):
        """Регистрация нового клиента."""
        email = request.data.get('email')
        phone = request.data.get('phone')
        name = request.data.get('name', '')
        password = request.data.get('password')
        
        if not email or not phone:
            return Response(
                {'error': 'Email и телефон обязательны'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Валидация пароля (если указан)
        if password:
            if len(password) < 8:
                return Response(
                    {'error': 'Пароль должен содержать минимум 8 символов'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            # Дополнительная валидация сложности пароля
            from django.contrib.auth.password_validation import validate_password
            from django.core.exceptions import ValidationError
            try:
                validate_password(password)
            except ValidationError as e:
                return Response(
                    {'error': '; '.join(e.messages)},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Проверяем, существует ли клиент с таким email
        customer = Customer.objects.filter(email=email).first()
        
        if customer and customer.is_registered:
            return Response(
                {'error': 'Клиент с таким email уже зарегистрирован'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Создаем или обновляем клиента
        if customer:
            customer.name = name
            customer.phone = phone
        else:
            customer = Customer.objects.create(
                email=email,
                phone=phone,
                name=name,
                is_registered=False,
                email_verified=False
            )
        
        # Если указан пароль, создаем пользователя Django
        # ВАЖНО: Django create_user() автоматически хеширует пароль перед сохранением
        # Пароль передается по HTTPS, что обеспечивает безопасность передачи
        if password:
            # Проверяем, существует ли пользователь
            user = User.objects.filter(email=email).first()
            if not user:
                # create_user() автоматически хеширует пароль через PBKDF2
                user = User.objects.create_user(
                    username=email,
                    email=email,
                    password=password  # Django автоматически хеширует это
                )
            else:
                # Если пользователь существует, обновляем пароль (хешируется автоматически)
                user.set_password(password)
                user.save()
            customer.user = user
            customer.is_registered = True
            
            # Авторизуем пользователя
            from django.contrib.auth import login
            login(request, user)
        
        # Генерируем токен подтверждения email
        verification_token = secrets.token_urlsafe(32)
        customer.email_verification_token = verification_token
        customer.save()
        
        # Отправляем email с подтверждением (если настроено)
        if hasattr(django_settings, 'EMAIL_HOST_USER') and django_settings.EMAIL_HOST_USER:
            verification_url = f"{request.build_absolute_uri('/')}api/customers/verify-email/?token={verification_token}"
            send_mail(
                subject='Подтверждение email - Este Nómada',
                message=f'Перейдите по ссылке для подтверждения email: {verification_url}',
                from_email=django_settings.EMAIL_HOST_USER,
                recipient_list=[email],
                fail_silently=True,
            )
        
        serializer = CustomerSerializer(customer, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        serializer = self.get_serializer(customer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def verify_email(self, request):
        """Подтверждение email по токену."""
        token = request.query_params.get('token')
        if not token:
            return Response(
                {'error': 'Токен не указан'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        customer = Customer.objects.filter(email_verification_token=token).first()
        if not customer:
            return Response(
                {'error': 'Неверный токен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        customer.email_verified = True
        customer.email_verification_token = None
        customer.is_registered = True
        customer.save()
        
        return Response({'message': 'Email успешно подтвержден'})
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def profile(self, request):
        """Получить профиль текущего пользователя."""
        customer = Customer.objects.filter(user=request.user).first()
        if not customer:
            return Response(
                {'error': 'Профиль не найден'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = self.get_serializer(customer)
        return Response(serializer.data)


class CartViewSet(viewsets.ModelViewSet):
    """ViewSet для корзины."""
    serializer_class = CartSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        """Получить корзину для текущего пользователя или сессии."""
        if self.request.user.is_authenticated:
            customer = Customer.objects.filter(user=self.request.user).first()
            if customer:
                return Cart.objects.filter(customer=customer)
        # Для неавторизованных используем session_key
        session_key = self.request.session.session_key
        if not session_key:
            self.request.session.create()
            session_key = self.request.session.session_key
        return Cart.objects.filter(session_key=session_key)
    
    def list(self, request, *args, **kwargs):
        """Возвращает корзину (создает, если не существует)."""
        cart = self.get_object()
        serializer = self.get_serializer(cart, context={'request': request})
        return Response(serializer.data)
    
    def get_object(self):
        """Получить или создать корзину."""
        queryset = self.get_queryset()
        cart = queryset.first()
        
        if not cart:
            if self.request.user.is_authenticated:
                customer = Customer.objects.filter(user=self.request.user).first()
                if customer:
                    cart = Cart.objects.create(customer=customer)
            else:
                session_key = self.request.session.session_key
                if not session_key:
                    self.request.session.create()
                    session_key = self.request.session.session_key
                cart = Cart.objects.create(session_key=session_key)
        
        return cart
    
    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """Добавить элемент в корзину."""
        cart = self.get_object()
        menu_item_id = request.data.get('menu_item_id')
        quantity = int(request.data.get('quantity', 1))
        
        if not menu_item_id:
            return Response(
                {'error': 'menu_item_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            menu_item = MenuItem.objects.get(id=menu_item_id, active=True)
        except MenuItem.DoesNotExist:
            return Response(
                {'error': 'Блюдо не найдено'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        cart_item, created = CartItem.objects.get_or_create(
            cart=cart,
            menu_item=menu_item,
            defaults={'quantity': quantity}
        )
        
        if not created:
            cart_item.quantity += quantity
            cart_item.save()
        
        serializer = CartItemDetailSerializer(cart_item, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def update_item(self, request, pk=None):
        """Обновить количество элемента в корзине."""
        cart = self.get_object()
        cart_item_id = request.data.get('cart_item_id')
        quantity = int(request.data.get('quantity', 1))
        
        if not cart_item_id:
            return Response(
                {'error': 'cart_item_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            cart_item = CartItem.objects.get(id=cart_item_id, cart=cart)
        except CartItem.DoesNotExist:
            return Response(
                {'error': 'Элемент корзины не найден'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if quantity <= 0:
            cart_item.delete()
            return Response({'message': 'Элемент удален из корзины'})
        
        cart_item.quantity = quantity
        cart_item.save()
        
        serializer = CartItemDetailSerializer(cart_item, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=True, methods=['delete'])
    def remove_item(self, request, pk=None):
        """Удалить элемент из корзины."""
        cart = self.get_object()
        cart_item_id = request.query_params.get('cart_item_id')
        
        if not cart_item_id:
            return Response(
                {'error': 'cart_item_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            cart_item = CartItem.objects.get(id=cart_item_id, cart=cart)
            cart_item.delete()
            return Response({'message': 'Элемент удален из корзины'})
        except CartItem.DoesNotExist:
            return Response(
                {'error': 'Элемент корзины не найден'},
                status=status.HTTP_404_NOT_FOUND
            )


class FavoriteViewSet(viewsets.ModelViewSet):
    """ViewSet для избранного."""
    serializer_class = FavoriteSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        """Получить избранное для текущего пользователя или сессии."""
        if self.request.user.is_authenticated:
            customer = Customer.objects.filter(user=self.request.user).first()
            if customer:
                return Favorite.objects.filter(customer=customer)
        # Для неавторизованных используем session_key
        session_key = self.request.session.session_key
        if not session_key:
            self.request.session.create()
            session_key = self.request.session.session_key
        return Favorite.objects.filter(session_key=session_key)
    
    def create(self, request, *args, **kwargs):
        """Добавить в избранное."""
        menu_item_id = request.data.get('menu_item_id')
        
        if not menu_item_id:
            return Response(
                {'error': 'menu_item_id обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            menu_item = MenuItem.objects.get(id=menu_item_id, active=True)
        except MenuItem.DoesNotExist:
            return Response(
                {'error': 'Блюдо не найдено'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Определяем customer или session_key
        customer = None
        session_key = None
        
        if request.user.is_authenticated:
            customer = Customer.objects.filter(user=request.user).first()
        else:
            session_key = request.session.session_key
            if not session_key:
                request.session.create()
                session_key = request.session.session_key
        
        # Проверяем, не добавлено ли уже
        if customer:
            favorite, created = Favorite.objects.get_or_create(
                customer=customer,
                menu_item=menu_item
            )
        else:
            favorite, created = Favorite.objects.get_or_create(
                session_key=session_key,
                menu_item=menu_item
            )
        
        if not created:
            return Response(
                {'error': 'Уже в избранном'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = self.get_serializer(favorite, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class DeliverySettingsViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet для настроек доставки."""
    queryset = DeliverySettings.objects.all()
    serializer_class = DeliverySettingsSerializer
    permission_classes = [AllowAny]
    
    def get_object(self):
        """Всегда возвращаем единственный экземпляр."""
        return DeliverySettings.get_settings()
    
    def list(self, request, *args, **kwargs):
        """Переопределяем list для возврата единственного объекта."""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def calculate(self, request):
        """Рассчитать стоимость доставки."""
        postal_code = request.data.get('postal_code')
        order_total = float(request.data.get('order_total', 0))
        
        if not postal_code:
            return Response(
                {'error': 'Почтовый индекс обязателен'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        settings = DeliverySettings.get_settings()
        result = settings.calculate_delivery_cost(postal_code, order_total)
        
        return Response(result, status=status.HTTP_200_OK if result.get('success') else status.HTTP_400_BAD_REQUEST)

