"""
Serializers for API.
"""
from rest_framework import serializers
import markdown
from core.models import (
    Story, StoryTranslation, MenuItem, MenuItemTranslation, MenuItemImage, MenuItemAttribute,
    HeroImage, HeroSettings, Settings, Order, OrderItem, InstagramPost, Translation,
    ContentSection, ContentSectionTranslation, FooterSection, FooterSectionTranslation
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
        fields = ['locale', 'name', 'description', 'category']
        read_only_fields = []


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


class MenuItemSerializer(serializers.ModelSerializer):
    """Сериализатор для блюд меню."""
    translations = MenuItemTranslationSerializer(many=True, read_only=True)
    images = MenuItemImageSerializer(many=True, read_only=True)
    attributes = MenuItemAttributeSerializer(many=True, read_only=True)
    related_stories = serializers.SerializerMethodField()
    
    class Meta:
        model = MenuItem
        fields = [
            'id', 'name', 'description', 'category', 'price',
            'image', 'order', 'active', 'translations', 'images', 'attributes',
            'related_stories', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
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
                data['category'] = translation.category
            # Если перевода нет, используются базовые поля из data (уже установлены через super())
            
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


class OrderSerializer(serializers.ModelSerializer):
    """Сериализатор для заказов."""
    order_items = OrderItemSerializer(many=True, read_only=True)
    selected_dishes = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = Order
        fields = [
            'id', 'name', 'phone', 'comment', 'status',
            'ai_response', 'order_items', 'selected_dishes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'status', 'ai_response', 'created_at', 'updated_at']


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

