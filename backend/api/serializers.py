"""
Serializers for API.
"""
from rest_framework import serializers
import markdown
from core.models import (
    Story, StoryTranslation, MenuItem, MenuItemTranslation, MenuItemImage, MenuItemAttribute,
    MenuItemCategory, MenuItemCategoryTranslation,
    HeroImage, HeroButton, HeroButtonTranslation, HeroSettings, Settings, Order, OrderItem, OrderReview, InstagramPost, Translation,
    ContentSection, ContentSectionTranslation, FooterSection, FooterSectionTranslation,
    Customer, Cart, CartItem, Favorite, DeliverySettings, Stock, Ingredient, MenuItemIngredient
)


class StoryTranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов историй."""
    
    class Meta:
        model = StoryTranslation
        fields = ['locale', 'title', 'slug', 'excerpt', 'content']
        read_only_fields = []


class StorySerializer(serializers.ModelSerializer):
    """Сериализатор для историй."""
    coverImage = serializers.SerializerMethodField()
    translations = StoryTranslationSerializer(many=True, read_only=True)
    
    class Meta:
        model = Story
        fields = [
            'id', 'title', 'slug', 'date', 'excerpt', 'content',
            'cover_image', 'cover_image_file', 'coverImage', 'source', 'published',
            'translations', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_coverImage(self, obj):
        """Возвращает URL обложки: сначала из загруженного файла, затем из URL поля."""
        request = self.context.get('request')
        if obj.cover_image_file and obj.cover_image_file.name:
            if request:
                return request.build_absolute_uri(obj.cover_image_file.url)
            return obj.cover_image_file.url
        return obj.cover_image
    
    def to_representation(self, instance):
        """Возвращаем данные с учётом локали из запроса."""
        data = super().to_representation(instance)
        request = self.context.get('request')
        
        # Используем coverImage для обратной совместимости
        if 'coverImage' in data:
            data['cover_image'] = data['coverImage']
        
        if request:
            locale = request.query_params.get('locale', 'ru')
            translation = instance.get_translation(locale)
            
            if translation:
                # Используем перевод, если есть
                data['title'] = translation.title
                data['slug'] = translation.slug
                data['excerpt'] = translation.excerpt
                content = translation.content
            else:
                content = data.get('content', '')
        else:
            content = data.get('content', '')
        
        # Преобразуем markdown в HTML
        if content:
            try:
                # Расширение 'extra' включает:
                # - таблицы
                # - списки определений
                # - fenced code blocks (блоки кода с обратными кавычками)
                # - атрибуты для заголовков
                # - и другие функции
                md = markdown.Markdown(extensions=['extra'])
                data['content'] = md.convert(content)
            except Exception as e:
                # Если преобразование не удалось, возвращаем как есть
                # В production можно логировать ошибку
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Markdown conversion failed: {e}")
                data['content'] = content
        
        return data


class MenuItemTranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов блюд."""
    
    class Meta:
        model = MenuItemTranslation
        fields = ['locale', 'name', 'description']
        read_only_fields = []


class MenuItemCategoryTranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов категорий блюд."""
    
    class Meta:
        model = MenuItemCategoryTranslation
        fields = ['locale', 'name', 'description']
        read_only_fields = []


class MenuItemCategorySerializer(serializers.ModelSerializer):
    """Сериализатор для категорий блюд."""
    translations = MenuItemCategoryTranslationSerializer(many=True, read_only=True)
    
    class Meta:
        model = MenuItemCategory
        fields = ['id', 'order_id', 'active', 'translations', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def to_representation(self, instance):
        """Возвращаем данные с учётом локали из запроса."""
        data = super().to_representation(instance)
        request = self.context.get('request')
        
        if request:
            locale = request.query_params.get('locale', 'ru')
            translation = instance.get_translation(locale)
            
            if translation:
                data['name'] = translation.name
                data['description'] = translation.description
            else:
                # Fallback на первый доступный перевод
                first_translation = instance.translations.first()
                if first_translation:
                    data['name'] = first_translation.name
                    data['description'] = first_translation.description
                else:
                    data['name'] = f'Категория #{instance.id}'
                    data['description'] = None
        
        return data


class MenuItemImageSerializer(serializers.ModelSerializer):
    """Сериализатор для изображений блюд."""
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = MenuItemImage
        fields = ['id', 'image_url', 'order']
        read_only_fields = ['id']
    
    def get_image_url(self, obj):
        """Возвращает URL изображения (приоритет: загруженный файл, затем URL)."""
        request = self.context.get('request')
        if obj.image:
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return obj.image_url


class MenuItemAttributeSerializer(serializers.ModelSerializer):
    """Сериализатор для атрибутов блюд."""
    
    class Meta:
        model = MenuItemAttribute
        fields = ['id', 'locale', 'name', 'value', 'order']
        read_only_fields = ['id']


class IngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для ингредиентов."""
    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'unit', 'description', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class MenuItemIngredientSerializer(serializers.ModelSerializer):
    """Сериализатор для связи блюда с ингредиентами."""
    ingredient = IngredientSerializer(read_only=True)
    ingredient_id = serializers.IntegerField(write_only=True, required=False)
    
    class Meta:
        model = MenuItemIngredient
        fields = ['id', 'ingredient', 'ingredient_id', 'quantity', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class StockSerializer(serializers.ModelSerializer):
    """Сериализатор для остатков на складе."""
    total_quantity = serializers.SerializerMethodField()
    low_stock_warning = serializers.SerializerMethodField()
    
    class Meta:
        model = Stock
        fields = [
            'id', 'menu_item', 'home_kitchen_quantity', 'delivery_kitchen_quantity',
            'total_quantity', 'low_stock_warning', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_total_quantity(self, obj):
        """Получить общее количество порций."""
        return obj.get_total_quantity()
    
    def get_low_stock_warning(self, obj):
        """Проверяет, нужно ли предупреждение о низком остатке."""
        return obj.get_low_stock_warning(threshold=5)


class MenuItemSerializer(serializers.ModelSerializer):
    """Сериализатор для блюд меню."""
    translations = MenuItemTranslationSerializer(many=True, read_only=True)
    images = MenuItemImageSerializer(many=True, read_only=True)
    attributes = MenuItemAttributeSerializer(many=True, read_only=True)
    related_stories = serializers.SerializerMethodField()
    category = MenuItemCategorySerializer(read_only=True)
    stock = StockSerializer(read_only=True)
    ingredients = MenuItemIngredientSerializer(many=True, read_only=True)
    stock_quantity = serializers.SerializerMethodField()
    low_stock = serializers.SerializerMethodField()
    
    class Meta:
        model = MenuItem
        fields = [
            'id', 'name', 'description', 'category', 'price',
            'image', 'order', 'active', 'translations', 'images', 'attributes',
            'related_stories', 'stock', 'ingredients', 'stock_quantity', 'low_stock',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_stock_quantity(self, obj):
        """Получить общее количество порций на складе."""
        if hasattr(obj, 'stock'):
            return obj.stock.get_total_quantity()
        return None
    
    def get_low_stock(self, obj):
        """Проверяет, нужно ли предупреждение о низком остатке."""
        if hasattr(obj, 'stock'):
            return obj.stock.get_low_stock_warning(threshold=5)
        return False
    
    def get_related_stories(self, obj):
        """Возвращает связанные истории с учетом локали."""
        request = self.context.get('request')
        locale = request.query_params.get('locale', 'ru') if request else 'ru'
        
        # Получаем только опубликованные истории
        stories = obj.related_stories.filter(published=True).order_by('-date')[:5]
        
        result = []
        for story in stories:
            translation = story.get_translation(locale)
            # Получаем URL обложки
            cover_image_url = None
            if story.cover_image_file and story.cover_image_file.name:
                if request:
                    cover_image_url = request.build_absolute_uri(story.cover_image_file.url)
                else:
                    cover_image_url = story.cover_image_file.url
            else:
                cover_image_url = story.cover_image
            
            result.append({
                'id': story.id,
                'title': translation.title if translation else story.title,
                'slug': translation.slug if translation else story.slug,
                'excerpt': translation.excerpt if translation else story.excerpt,
                'coverImage': cover_image_url,
                'date': story.date.isoformat() if hasattr(story.date, 'isoformat') else str(story.date),
            })
        
        return result
    
    def to_representation(self, instance):
        """Возвращаем данные с учётом локали из запроса."""
        data = super().to_representation(instance)
        request = self.context.get('request')
        
        if request:
            locale = request.query_params.get('locale', 'ru')
            translation = instance.get_translation(locale)
            
            if translation:
                # Используем перевод, если есть
                data['name'] = translation.name
                # Описание: если в переводе есть описание, используем его, иначе базовое
                # Описание возвращаем как есть (HTML не экранируется, так как это TextField)
                data['description'] = translation.description if translation.description else data.get('description')
            # Если перевода нет, используются базовые поля из data (уже установлены через super())
            # category уже сериализуется через MenuItemCategorySerializer
            
            # Фильтруем атрибуты по текущей локали
            if 'attributes' in data and data['attributes']:
                data['attributes'] = [
                    attr for attr in data['attributes']
                    if attr.get('locale') == locale
                ]
        
        return data


class SettingsSerializer(serializers.ModelSerializer):
    """Сериализатор для настроек."""
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Settings
        fields = [
            'id', 'site_name', 'logo_url', 'site_description', 'contact_email',
            'telegram_channel', 'bot_token', 'channel_id', 'auto_sync',
            'updated_at'
        ]
        read_only_fields = ['id', 'logo_url', 'updated_at']
    
    def get_logo_url(self, obj):
        """Возвращает URL логотипа."""
        if not obj.logo:
            return None
        
        request = self.context.get('request')
        logo_url = obj.logo.url
        
        # Если URL уже абсолютный, возвращаем как есть
        if logo_url.startswith('http://') or logo_url.startswith('https://'):
            return logo_url
        
        # Если есть request, строим абсолютный URL
        if request:
            return request.build_absolute_uri(logo_url)
        
        # Иначе возвращаем относительный URL
        return logo_url


class OrderItemSerializer(serializers.ModelSerializer):
    """Сериализатор для элементов заказа."""
    menu_item = MenuItemSerializer(read_only=True)
    menu_item_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = OrderItem
        fields = ['id', 'menu_item', 'menu_item_id', 'quantity']
        read_only_fields = ['id']


class OrderReviewSerializer(serializers.ModelSerializer):
    """Сериализатор для отзывов на заказы."""
    class Meta:
        model = OrderReview
        fields = ['id', 'rating', 'comment', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class OrderSerializer(serializers.ModelSerializer):
    """Сериализатор для заказов."""
    order_items = OrderItemSerializer(many=True, read_only=True)
    selected_dishes = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        required=False,
        help_text='Список блюд: [{"menu_item_id": 1, "quantity": 2}, ...]'
    )
    email_display = serializers.SerializerMethodField()
    phone_display = serializers.SerializerMethodField()
    total = serializers.SerializerMethodField()
    review = OrderReviewSerializer(read_only=True)
    can_review = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = [
            'id', 'customer', 'name', 'email', 'email_display', 'phone', 'phone_display',
            'is_pickup', 'postal_code', 'address', 'delivery_cost', 'delivery_distance',
            'comment', 'status', 'ai_response', 'order_items', 'selected_dishes',
            'total', 'created_at', 'updated_at', 'review', 'can_review'
        ]
        read_only_fields = ['id', 'status', 'ai_response', 'created_at', 'updated_at']
        extra_kwargs = {
            'email': {'write_only': True},
            'phone': {'write_only': True},
        }
    
    def get_can_review(self, obj):
        """Проверяет, может ли пользователь оставить отзыв на этот заказ."""
        # Можно оставить отзыв только для завершенных или отмененных заказов
        # Проверяем, есть ли уже отзыв
        has_review = hasattr(obj, 'review') and obj.review is not None
        return obj.status in ['completed', 'cancelled'] and not has_review
    
    def get_email_display(self, obj):
        """Получить маскированный email для отображения."""
        if obj.customer:
            return obj.customer.get_email_display()
        # Для старых заказов без customer
        if obj.email:
            parts = obj.email.split('@')
            if len(parts) == 2:
                username = parts[0]
                domain = parts[1]
                if len(username) > 2:
                    masked = username[0] + '*' * (len(username) - 2) + username[-1]
                else:
                    masked = '*' * len(username)
                return f'{masked}@{domain}'
        return obj.email
    
    def get_phone_display(self, obj):
        """Получить маскированный телефон для отображения."""
        if obj.customer:
            return obj.customer.get_phone_display()
        # Для старых заказов без customer
        if obj.phone and len(obj.phone) > 4:
            return obj.phone[:2] + '*' * (len(obj.phone) - 4) + obj.phone[-2:]
        return obj.phone
    
    def get_total(self, obj):
        """Получить общую стоимость заказа."""
        return obj.get_total()
    
    def create(self, validated_data):
        """Создание заказа с исключением selected_dishes из validated_data."""
        # Удаляем selected_dishes, так как это не поле модели
        validated_data.pop('selected_dishes', None)
        return super().create(validated_data)


class InstagramPostSerializer(serializers.ModelSerializer):
    """Сериализатор для Instagram постов."""
    
    class Meta:
        model = InstagramPost
        fields = [
            'id', 'instagram_id', 'caption', 'media_url',
            'media_type', 'permalink', 'timestamp',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов."""
    
    class Meta:
        model = Translation
        fields = ['id', 'locale', 'namespace', 'key', 'value', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class HeroImageSerializer(serializers.ModelSerializer):
    """Сериализатор для Hero изображений."""
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = HeroImage
        fields = ['id', 'image_url', 'order', 'active']
        read_only_fields = ['id', 'image_url']
    
    def get_image_url(self, obj):
        """Возвращает URL изображения с приоритетом загруженного файла."""
        request = self.context.get('request')
        
        # Приоритет у загруженного файла
        if obj.image:
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        
        # Fallback на URL
        return obj.image_url if obj.image_url else None


class HeroButtonTranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов кнопок Hero."""
    
    class Meta:
        model = HeroButtonTranslation
        fields = ['locale', 'text']


class HeroButtonSerializer(serializers.ModelSerializer):
    """Сериализатор для кнопок Hero."""
    translations = HeroButtonTranslationSerializer(many=True, read_only=True)
    text = serializers.SerializerMethodField()
    
    class Meta:
        model = HeroButton
        fields = ['id', 'order', 'url', 'style', 'active', 'open_in_new_tab', 'translations', 'text', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_text(self, obj):
        """Возвращает текст кнопки для текущей локали."""
        request = self.context.get('request')
        locale = 'ru'  # По умолчанию
        
        if request:
            # Пробуем получить локаль из query параметра
            locale = request.query_params.get('locale', 'ru')
            # Или из Accept-Language заголовка
            if locale == 'ru':
                accept_language = request.META.get('HTTP_ACCEPT_LANGUAGE', '')
                if 'es' in accept_language.lower():
                    locale = 'es'
                elif 'en' in accept_language.lower():
                    locale = 'en'
        
        # Ищем перевод для указанной локали
        translation = obj.translations.filter(locale=locale).first()
        if translation:
            return translation.text
        
        # Fallback на первый доступный перевод
        first_translation = obj.translations.first()
        if first_translation:
            return first_translation.text
        
        return ''


class HeroSettingsSerializer(serializers.ModelSerializer):
    """Сериализатор для настроек Hero."""
    
    class Meta:
        model = HeroSettings
        fields = ['slide_interval', 'transition_effect', 'updated_at']
        read_only_fields = ['updated_at']


class ContentSectionTranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов разделов контента."""
    
    class Meta:
        model = ContentSectionTranslation
        fields = ['locale', 'title', 'subtitle', 'description', 'content']
        read_only_fields = []


class ContentSectionSerializer(serializers.ModelSerializer):
    """Сериализатор для разделов контента."""
    image_url = serializers.SerializerMethodField()
    translations = ContentSectionTranslationSerializer(many=True, read_only=True)
    section_type_display = serializers.CharField(source='get_section_type_display', read_only=True)
    
    class Meta:
        model = ContentSection
        fields = [
            'id', 'section_type', 'section_type_display', 'section_id',
            'title', 'subtitle', 'description', 'content', 'image_url',
            'order', 'published', 'translations', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_image_url(self, obj):
        """Возвращает URL изображения (приоритет: загруженный файл, затем URL)."""
        request = self.context.get('request')
        if obj.image:
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return obj.image_url
    
    def to_representation(self, instance):
        """Возвращаем данные с учётом локали из запроса."""
        data = super().to_representation(instance)
        request = self.context.get('request')
        
        if request:
            locale = request.query_params.get('locale', 'ru')
            translation = instance.get_translation(locale)
            
            if translation:
                # Используем перевод, если есть
                data['title'] = translation.title
                data['subtitle'] = translation.subtitle
                # Описание и контент возвращаем как есть (HTML не экранируется, так как это TextField)
                data['description'] = translation.description if translation.description else data.get('description')
                data['content'] = translation.content if translation.content else data.get('content')
            # Если перевода нет, используются базовые поля из data (уже установлены через super())
        
        return data


# Для обратной совместимости
AboutSectionSerializer = ContentSectionSerializer


class FooterSectionTranslationSerializer(serializers.ModelSerializer):
    """Сериализатор для переводов секций футера."""
    class Meta:
        model = FooterSectionTranslation
        fields = ['locale', 'title', 'content']
        read_only_fields = []


class FooterSectionSerializer(serializers.ModelSerializer):
    """Сериализатор для секций футера."""
    translations = FooterSectionTranslationSerializer(many=True, read_only=True)
    position_display = serializers.CharField(source='get_position_display', read_only=True)
    text_align_display = serializers.CharField(source='get_text_align_display', read_only=True)
    
    class Meta:
        model = FooterSection
        fields = [
            'id', 'title', 'content', 'position', 'position_display', 'text_align', 'text_align_display',
            'order', 'published', 'translations', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def to_representation(self, instance):
        """Возвращаем данные с учётом локали из запроса."""
        data = super().to_representation(instance)
        request = self.context.get('request')
        
        if request:
            locale = request.query_params.get('locale', 'ru')
            # Ищем перевод для запрошенной локали
            translation = instance.translations.filter(locale=locale).first()
            
            if translation:
                # Возвращаем title и content как есть, без экранирования (они содержат HTML)
                data['title'] = translation.title
                data['content'] = translation.content
            else:
                # Если нет перевода, используем базовые поля
                data['title'] = instance.title
                data['content'] = instance.content
        
        return data


# ============================================
# ЛИЧНЫЙ КАБИНЕТ И КОРЗИНА
# ============================================

class CustomerSerializer(serializers.ModelSerializer):
    """Сериализатор для клиента."""
    email_display = serializers.CharField(source='get_email_display', read_only=True)
    phone_display = serializers.CharField(source='get_phone_display', read_only=True)
    email_readable = serializers.SerializerMethodField()
    phone_readable = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = [
            'id', 'user', 'email', 'email_display', 'email_readable', 'phone', 'phone_display', 'phone_readable',
            'name', 'postal_code', 'address', 'is_registered', 'email_verified',
            'created_at', 'updated_at', 'last_login'
        ]
        read_only_fields = ['id', 'is_registered', 'email_verified', 'created_at', 'updated_at', 'last_login']
        extra_kwargs = {
            'email': {'write_only': True},
            'phone': {'write_only': True},
        }
    
    def get_email_readable(self, obj):
        """Возвращает реальный email только для текущего пользователя."""
        request = self.context.get('request')
        if request and request.user.is_authenticated and obj.user == request.user:
            return obj.email
        return None
    
    def get_phone_readable(self, obj):
        """Возвращает реальный телефон только для текущего пользователя."""
        request = self.context.get('request')
        if request and request.user.is_authenticated and obj.user == request.user:
            return obj.phone
        return None


class CartItemDetailSerializer(serializers.ModelSerializer):
    """Сериализатор для элементов корзины."""
    menu_item = MenuItemSerializer(read_only=True)
    menu_item_id = serializers.IntegerField(write_only=True)
    subtotal = serializers.SerializerMethodField()
    
    class Meta:
        model = CartItem
        fields = ['id', 'menu_item', 'menu_item_id', 'quantity', 'subtotal', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_subtotal(self, obj):
        """Получить стоимость элемента."""
        return obj.get_subtotal()


class CartSerializer(serializers.ModelSerializer):
    """Сериализатор для корзины."""
    items = CartItemDetailSerializer(many=True, read_only=True)
    total = serializers.SerializerMethodField()
    total_items = serializers.SerializerMethodField()
    
    class Meta:
        model = Cart
        fields = ['id', 'customer', 'session_key', 'items', 'total', 'total_items', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_total(self, obj):
        """Получить общую стоимость корзины."""
        return obj.get_total()
    
    def get_total_items(self, obj):
        """Получить общее количество товаров."""
        return obj.get_total_items()


class FavoriteSerializer(serializers.ModelSerializer):
    """Сериализатор для избранного."""
    menu_item = MenuItemSerializer(read_only=True)
    menu_item_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Favorite
        fields = ['id', 'customer', 'session_key', 'menu_item', 'menu_item_id', 'created_at']
        read_only_fields = ['id', 'created_at']


class DeliverySettingsSerializer(serializers.ModelSerializer):
    """Сериализатор для настроек доставки."""
    
    class Meta:
        model = DeliverySettings
        fields = [
            'id', 'delivery_point_latitude', 'delivery_point_longitude',
            'base_delivery_cost', 'cost_per_km', 'free_delivery_threshold',
            'max_delivery_distance', 'cart_enabled', 'favorites_enabled',
            'registration_required', 'updated_at'
        ]
        read_only_fields = ['id', 'updated_at']

