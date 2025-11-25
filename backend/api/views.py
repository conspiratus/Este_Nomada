"""
API Views.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.shortcuts import get_object_or_404
from core.models import Story, MenuItem, Settings, Order, OrderItem, InstagramPost, Translation, HeroImage, HeroSettings, ContentSection, FooterSection
from .serializers import (
    StorySerializer, MenuItemSerializer, SettingsSerializer,
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
    
    def get_permissions(self):
        """Разные права доступа."""
        if self.action == 'create':
            return [AllowAny()]
        return [IsAuthenticated()]
    
    def create(self, request, *args, **kwargs):
        """Создание заказа с элементами."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        selected_dishes = request.data.get('selected_dishes', [])
        order = serializer.save()
        
        # Создаём элементы заказа
        for dish_id in selected_dishes:
            try:
                menu_item = MenuItem.objects.get(id=dish_id, active=True)
                OrderItem.objects.create(
                    order=order,
                    menu_item=menu_item,
                    quantity=1
                )
            except MenuItem.DoesNotExist:
                pass
        
        # Здесь будет обработка через OpenAI (в задаче Celery)
        from .tasks import process_order_with_ai
        process_order_with_ai.delay(order.id)
        
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

