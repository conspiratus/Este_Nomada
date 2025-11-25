"""
Django Admin configuration for core models.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django import forms
from django.db import models
from django.utils.html import format_html
from .models import (
    Story, StoryTranslation, MenuItem, MenuItemTranslation, MenuItemImage, MenuItemAttribute,
    HeroImage, HeroSettings, Settings, Order, OrderItem, InstagramPost, Translation,
    ContentSection, ContentSectionTranslation, FooterSection, FooterSectionTranslation,
    DishTTK, TTKVersionHistory
)

# Стандартная модель User уже зарегистрирована в Django Admin


class StoryTranslationInline(admin.TabularInline):
    """Inline для переводов историй."""
    model = StoryTranslation
    extra = 1
    fields = ['locale', 'title', 'slug', 'excerpt', 'content']
    prepopulated_fields = {'slug': ('title',)}


@admin.register(Story)
class StoryAdmin(admin.ModelAdmin):
    """Админка для историй."""
    list_display = ['title', 'slug', 'date', 'source', 'published', 'created_at', 'cover_preview']
    list_filter = ['source', 'published', 'date']
    search_fields = ['title', 'slug', 'content']
    prepopulated_fields = {'slug': ('title',)}
    readonly_fields = ['created_at', 'updated_at', 'cover_preview', 'cover_info']
    inlines = [StoryTranslationInline]
    fieldsets = (
        ('Основная информация (базовая)', {
            'fields': ('title', 'slug', 'date', 'excerpt', 'content'),
            'description': 'Эти поля используются как fallback, если нет перевода для нужной локали'
        }),
        ('Медиа', {
            'fields': ('cover_image_file', 'cover_preview', 'cover_info', 'cover_image'),
            'description': 'Загрузите изображение через поле "Обложка (загрузка файла)" - оно будет автоматически оптимизировано (сжато, изменен размер до 1920px, конвертировано в WebP). Или укажите URL в поле "Обложка (URL)".'
        }),
        ('Настройки', {
            'fields': ('source', 'published')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def cover_preview(self, obj):
        """Предпросмотр обложки."""
        from django.utils.html import format_html
        if obj.cover_image_file and obj.cover_image_file.name:
            return format_html(
                f'<img src="{obj.cover_image_file.url}" style="max-height: 200px; max-width: 400px; border-radius: 4px;" />'
            )
        elif obj.cover_image:
            return format_html(
                f'<img src="{obj.cover_image}" style="max-height: 200px; max-width: 400px; border-radius: 4px;" />'
            )
        return format_html('<span style="color: #999;">-</span>')
    cover_preview.short_description = 'Предпросмотр обложки'
    
    def cover_info(self, obj):
        """Информация об обложке."""
        from django.utils.html import format_html
        if not obj.cover_image_file or not obj.cover_image_file.name:
            return '-'
        from .utils import get_image_info
        info = get_image_info(obj.cover_image_file)
        if info:
            file_size_mb = info['file_size'] / (1024 * 1024) if info['file_size'] else 0
            return format_html(
                f"{info['width']}×{info['height']}px, {info['format']}, {file_size_mb:.2f}MB"
            )
        return '-'
    cover_info.short_description = 'Информация об обложке'


class MenuItemTranslationForm(forms.ModelForm):
    """Форма для переводов блюд с поддержкой HTML в описании."""
    class Meta:
        model = MenuItemTranslation
        fields = '__all__'
        widgets = {
            'description': forms.Textarea(attrs={'rows': 4, 'cols': 40}),
        }


class MenuItemTranslationInline(admin.TabularInline):
    """Inline для переводов блюд."""
    model = MenuItemTranslation
    form = MenuItemTranslationForm
    extra = 1
    fields = ['locale', 'name', 'description', 'category']


class MenuItemImageInline(admin.TabularInline):
    """Inline для изображений блюд."""
    model = MenuItemImage
    extra = 1
    fields = ['image', 'image_url', 'order']
    readonly_fields = ['image_preview']
    
    def image_preview(self, obj):
        """Предпросмотр изображения."""
        if obj.image:
            return f'<img src="{obj.image.url}" style="max-height: 100px; max-width: 200px;" />'
        elif obj.image_url:
            return f'<img src="{obj.image_url}" style="max-height: 100px; max-width: 200px;" />'
        return '-'
    image_preview.short_description = 'Предпросмотр'
    image_preview.allow_tags = True


class MenuItemAttributeInline(admin.TabularInline):
    """Inline для атрибутов блюд."""
    model = MenuItemAttribute
    extra = 1
    fields = ['locale', 'name', 'value', 'order']
    verbose_name = 'Атрибут'
    verbose_name_plural = 'Атрибуты'


class MenuItemAdminForm(forms.ModelForm):
    """Форма для блюд с поддержкой HTML в описании."""
    class Meta:
        model = MenuItem
        fields = '__all__'
        widgets = {
            'description': forms.Textarea(attrs={'rows': 4, 'cols': 40}),
        }


@admin.register(MenuItem)
class MenuItemAdmin(admin.ModelAdmin):
    """Админка для блюд меню."""
    form = MenuItemAdminForm
    list_display = ['name', 'category', 'price', 'order', 'active', 'created_at']
    list_filter = ['category', 'active']
    search_fields = ['name', 'description']
    list_editable = ['order', 'active']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [MenuItemTranslationInline, MenuItemImageInline, MenuItemAttributeInline]
    fieldsets = (
        ('Основная информация (базовая)', {
            'fields': ('name', 'description', 'category'),
            'description': 'Эти поля используются как fallback, если нет перевода для нужной локали. Поле "Описание" поддерживает HTML.'
        }),
        ('Цена и изображение', {
            'fields': ('price', 'image')
        }),
        ('Связанные истории', {
            'fields': ('related_stories',),
            'description': 'Выберите истории, которые связаны с этим блюдом. Они будут отображаться в карточке блюда.'
        }),
        ('Настройки', {
            'fields': ('order', 'active')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


# ============================================
# ГРУППА: HERO КАРУСЕЛЬ
# ============================================
class HeroImageAdmin(admin.ModelAdmin):
    """Админка для Hero изображений."""
    list_display = ['id', 'order', 'image_preview', 'image_info', 'image_url', 'active', 'created_at']
    list_display_links = ['id']
    list_filter = ['active', 'created_at']
    list_editable = ['order', 'active']
    readonly_fields = ['created_at', 'updated_at', 'image_preview', 'image_info']
    fieldsets = (
        ('Изображение', {
            'fields': ('image', 'image_preview', 'image_info', 'image_url', 'order', 'active'),
            'description': 'Загрузите изображение через поле "Изображение" - оно будет автоматически оптимизировано (сжато, изменен размер до 1920px, конвертировано в WebP). Или укажите URL в поле "URL изображения". Приоритет у загруженного файла.'
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def image_preview(self, obj):
        """Предпросмотр изображения."""
        if obj.image:
            return f'<img src="{obj.image.url}" style="max-height: 150px; max-width: 300px; border-radius: 4px;" />'
        elif obj.image_url:
            return f'<img src="{obj.image_url}" style="max-height: 150px; max-width: 300px; border-radius: 4px;" />'
        return '<span style="color: #999;">Изображение не загружено</span>'
    
    image_preview.short_description = 'Предпросмотр'
    image_preview.allow_tags = True
    
    def image_info(self, obj):
        """Информация об изображении."""
        if not obj.image or not obj.image.name:
            return '-'
        
        from .utils import get_image_info
        info = get_image_info(obj.image)
        if info:
            file_size_mb = info['file_size'] / (1024 * 1024) if info['file_size'] else 0
            return f"{info['width']}×{info['height']}px, {info['format']}, {file_size_mb:.2f}MB"
        return '-'
    
    image_info.short_description = 'Информация'
    image_info.allow_tags = False


class HeroSettingsAdmin(admin.ModelAdmin):
    """Админка для настроек Hero."""
    def has_add_permission(self, request):
        # Разрешаем только один экземпляр
        return not HeroSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False

    readonly_fields = ['updated_at']
    fieldsets = (
        ('Настройки карусели', {
            'fields': ('slide_interval', 'transition_effect'),
            'description': 'Интервал переключения слайдов в миллисекундах (минимум 1000мс) и эффект перехода'
        }),
        ('Дата обновления', {
            'fields': ('updated_at',),
            'classes': ('collapse',)
        }),
    )


# Регистрируем модели Hero
admin.site.register(HeroImage, HeroImageAdmin)
admin.site.register(HeroSettings, HeroSettingsAdmin)


@admin.register(Settings)
class SettingsAdmin(admin.ModelAdmin):
    """Админка для настроек сайта."""
    list_display = ['site_name', 'logo_preview', 'contact_email', 'updated_at']
    readonly_fields = ['updated_at', 'logo_preview', 'logo_info']
    
    def has_add_permission(self, request):
        # Разрешаем только один экземпляр
        return not Settings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False
    
    fieldsets = (
        ('Основные настройки', {
            'fields': ('site_name', 'logo', 'logo_preview', 'logo_info', 'site_description'),
            'description': 'Загрузите логотип через поле "Логотип сайта" - он будет автоматически оптимизирован (сжато, изменен размер до 512px, конвертировано в WebP).'
        }),
        ('Контакты', {
            'fields': ('contact_email', 'telegram_channel')
        }),
        ('Telegram интеграция', {
            'fields': ('bot_token', 'channel_id', 'auto_sync'),
            'classes': ('collapse',)
        }),
        ('Системная информация', {
            'fields': ('updated_at',),
            'classes': ('collapse',)
        }),
    )
    
    def logo_preview(self, obj):
        """Предпросмотр логотипа."""
        if obj.logo:
            return f'<img src="{obj.logo.url}" style="max-height: 100px; max-width: 200px; border-radius: 4px;" />'
        return '<span style="color: #999;">Логотип не загружен</span>'
    
    logo_preview.short_description = 'Предпросмотр логотипа'
    logo_preview.allow_tags = True
    
    def logo_info(self, obj):
        """Информация о логотипе."""
        if not obj.logo or not obj.logo.name:
            return '-'
        
        from .utils import get_image_info
        info = get_image_info(obj.logo)
        if info:
            file_size_mb = info['file_size'] / (1024 * 1024) if info['file_size'] else 0
            return f"{info['width']}×{info['height']}px, {info['format']}, {file_size_mb:.2f}MB"
        return '-'
    
    logo_info.short_description = 'Информация'
    logo_info.allow_tags = False


class OrderItemInline(admin.TabularInline):
    """Inline для элементов заказа."""
    model = OrderItem
    extra = 0
    readonly_fields = ['menu_item']


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    """Админка для заказов."""
    list_display = ['id', 'name', 'phone', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['name', 'phone', 'comment']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [OrderItemInline]
    fieldsets = (
        ('Информация о заказе', {
            'fields': ('name', 'phone', 'comment', 'status')
        }),
        ('AI обработка', {
            'fields': ('ai_response',),
            'classes': ('collapse',)
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(InstagramPost)
class InstagramPostAdmin(admin.ModelAdmin):
    """Админка для Instagram постов."""
    list_display = ['instagram_id', 'media_type', 'timestamp', 'created_at']
    list_filter = ['media_type', 'timestamp']
    search_fields = ['caption', 'instagram_id']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Translation)
class TranslationAdmin(admin.ModelAdmin):
    """Админка для переводов."""
    list_display = ['locale', 'namespace', 'key', 'value', 'updated_at']
    list_filter = ['locale', 'namespace', 'updated_at']
    search_fields = ['key', 'value', 'namespace']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Основная информация', {
            'fields': ('locale', 'namespace', 'key', 'value')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


class ContentSectionTranslationForm(forms.ModelForm):
    """Форма для переводов разделов контента с поддержкой HTML в описании."""
    class Meta:
        model = ContentSectionTranslation
        fields = '__all__'
        widgets = {
            'description': forms.Textarea(attrs={'rows': 6, 'cols': 40}),
            'content': forms.Textarea(attrs={'rows': 6, 'cols': 40}),
        }


class ContentSectionAdminForm(forms.ModelForm):
    """Форма для разделов контента с поддержкой HTML в описании."""
    class Meta:
        model = ContentSection
        fields = '__all__'
        widgets = {
            'description': forms.Textarea(attrs={'rows': 6, 'cols': 40}),
            'content': forms.Textarea(attrs={'rows': 6, 'cols': 40}),
        }


class ContentSectionTranslationInline(admin.TabularInline):
    """Inline для переводов разделов контента."""
    model = ContentSectionTranslation
    form = ContentSectionTranslationForm
    extra = 1
    fields = ['locale', 'title', 'subtitle', 'description', 'content']


@admin.register(ContentSection)
class ContentSectionAdmin(admin.ModelAdmin):
    """Админка для разделов контента."""
    form = ContentSectionAdminForm
    list_display = ['section_type', 'section_id', 'title', 'order', 'published', 'created_at']
    list_filter = ['section_type', 'published', 'created_at']
    search_fields = ['section_id', 'title', 'description']
    list_editable = ['order', 'published']
    readonly_fields = ['created_at', 'updated_at', 'image_preview', 'image_info']
    inlines = [ContentSectionTranslationInline]
    fieldsets = (
        ('Идентификация', {
            'fields': ('section_type', 'section_id'),
            'description': 'Тип раздела и уникальный ID (например: about, services-main, team-1)'
        }),
        ('Основная информация (базовая)', {
            'fields': ('title', 'subtitle', 'description', 'content'),
            'description': 'Эти поля используются как fallback, если нет перевода для нужной локали. Поля "Описание" и "Дополнительный контент" поддерживают HTML.'
        }),
        ('Изображение', {
            'fields': ('image', 'image_preview', 'image_info', 'image_url'),
            'description': 'Загрузите изображение через поле "Изображение" - оно будет автоматически оптимизировано (сжато, изменен размер до 1920px, конвертировано в WebP). Или укажите URL в поле "URL изображения".'
        }),
        ('Настройки', {
            'fields': ('order', 'published')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def image_preview(self, obj):
        """Предпросмотр изображения."""
        if obj.image:
            return f'<img src="{obj.image.url}" style="max-height: 200px; max-width: 400px; border-radius: 4px;" />'
        elif obj.image_url:
            return f'<img src="{obj.image_url}" style="max-height: 200px; max-width: 400px; border-radius: 4px;" />'
        return '<span style="color: #999;">-</span>'
    image_preview.short_description = 'Предпросмотр'
    image_preview.allow_tags = True
    
    def image_info(self, obj):
        """Информация об изображении."""
        if not obj.image or not obj.image.name:
            return '-'
        
        from .utils import get_image_info
        info = get_image_info(obj.image)
        if info:
            file_size_mb = info['file_size'] / (1024 * 1024) if info['file_size'] else 0
            return f"{info['width']}×{info['height']}px, {info['format']}, {file_size_mb:.2f}MB"
        return '-'
    
    image_info.short_description = 'Информация'
    image_info.allow_tags = False


class FooterSectionAdminForm(forms.ModelForm):
    """Форма для FooterSection с поддержкой HTML в title."""
    title = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 3, 'cols': 80}),
        required=False,
        help_text='Поддерживает HTML. Введите HTML код напрямую, он будет сохранён как есть.'
    )
    
    class Meta:
        model = FooterSection
        fields = '__all__'
    
    def clean_title(self):
        """Возвращаем title как есть, без экранирования."""
        title = self.cleaned_data.get('title', '')
        # Возвращаем как есть, Django не будет экранировать при сохранении в БД
        return title


class FooterSectionTranslationForm(forms.ModelForm):
    """Форма для переводов FooterSection с поддержкой HTML в title."""
    title = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 2, 'cols': 60}),
        required=False,
        help_text='Поддерживает HTML'
    )
    
    class Meta:
        model = FooterSectionTranslation
        fields = '__all__'
    
    def clean_title(self):
        """Возвращаем title как есть, без экранирования."""
        title = self.cleaned_data.get('title', '')
        return title


class FooterSectionTranslationInline(admin.TabularInline):
    """Inline для переводов секций футера."""
    model = FooterSectionTranslation
    extra = 1
    fields = ['locale', 'title', 'content']
    form = FooterSectionTranslationForm


@admin.register(FooterSection)
class FooterSectionAdmin(admin.ModelAdmin):
    """Админка для секций футера."""
    form = FooterSectionAdminForm
    list_display = ['title', 'position', 'text_align', 'order', 'published', 'created_at']
    list_filter = ['position', 'text_align', 'published', 'created_at']
    search_fields = ['title', 'content']
    list_editable = ['position', 'text_align', 'order', 'published']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [FooterSectionTranslationInline]
    fieldsets = (
        ('Основная информация (базовая)', {
            'fields': ('title', 'content'),
            'description': 'Эти поля используются как fallback, если нет перевода для нужной локали. Поддерживают HTML.'
        }),
        ('Размещение', {
            'fields': ('position', 'text_align', 'order')
        }),
        ('Настройки', {
            'fields': ('published',)
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


# ============================================
# ГРУППА: ТТК БЛЮД
# ============================================
class DishTTKAdminForm(forms.ModelForm):
    """Форма для админки ТТК с валидацией файла."""
    
    class Meta:
        model = DishTTK
        fields = '__all__'
        widgets = {
            'ttk_file': forms.FileInput(attrs={'accept': '.md'}),
        }
    
    def clean_ttk_file(self):
        """Валидация: файл должен быть в формате .md"""
        ttk_file = self.cleaned_data.get('ttk_file')
        if ttk_file:
            # Проверяем расширение файла
            if not ttk_file.name.lower().endswith('.md'):
                raise forms.ValidationError('Файл должен быть в формате Markdown (.md)')
        return ttk_file


@admin.register(DishTTK)
class DishTTKAdmin(admin.ModelAdmin):
    """Админка для технико-технологических карт блюд."""
    form = DishTTKAdminForm
    list_display = ['menu_item', 'version', 'file_name_display', 'active', 'created_at', 'updated_at']
    list_filter = ['active', 'created_at', 'updated_at']
    search_fields = ['menu_item__name', 'version', 'notes']
    list_editable = ['active']
    readonly_fields = ['created_at', 'updated_at', 'file_preview']
    
    def file_name_display(self, obj):
        """Отображение имени файла в списке."""
        return obj.get_file_name() if obj.get_file_name() else '-'
    file_name_display.short_description = 'Файл'
    fieldsets = (
        ('Основная информация', {
            'fields': ('menu_item', 'ttk_file', 'file_preview'),
            'description': 'Выберите блюдо и загрузите файл ТТК в формате Markdown (.md)'
        }),
        ('Дополнительная информация', {
            'fields': ('version', 'notes'),
            'description': 'Версия ТТК и дополнительные примечания'
        }),
        ('Настройки', {
            'fields': ('active',)
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def file_preview(self, obj):
        """Предпросмотр информации о файле."""
        if obj and obj.ttk_file:
            file_name = obj.get_file_name()
            file_url = obj.ttk_file.url if obj.ttk_file else None
            if file_url:
                return format_html('<a href="{}" target="_blank">{}</a>', file_url, file_name)
            return file_name
        return 'Файл не загружен'
    file_preview.short_description = 'Файл ТТК'


@admin.register(TTKVersionHistory)
class TTKVersionHistoryAdmin(admin.ModelAdmin):
    """Админка для истории версий ТТК."""
    list_display = ['ttk', 'version', 'changed_by', 'created_at']
    list_filter = ['created_at', 'ttk']
    search_fields = ['ttk__menu_item__name', 'version', 'change_description']
    readonly_fields = ['created_at']
    fieldsets = (
        ('Основная информация', {
            'fields': ('ttk', 'version', 'content', 'changed_by', 'change_description')
        }),
        ('Дата', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

