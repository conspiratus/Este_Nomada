"""
Django Admin configuration for core models.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django import forms
from django.db import models
from django.utils.html import format_html
from django.contrib.admin import AdminSite
from django.apps import apps
from .models import (
    Story, StoryTranslation, MenuItem, MenuItemTranslation, MenuItemImage, MenuItemAttribute,
    MenuItemCategory, MenuItemCategoryTranslation,
    HeroImage, HeroButton, HeroButtonTranslation, HeroSettings, Settings, Order, OrderItem, OrderReview, InstagramPost, Translation,
    ContentSection, ContentSectionTranslation, FooterSection, FooterSectionTranslation,
    DishTTK, TTKVersionHistory, Customer, Cart, CartItem, Favorite, DeliverySettings,
    Stock, Supplier, PriceSource, IngredientCategory, Ingredient, MenuItemIngredient, IngredientStock,
    TelegramAdminBotSettings, TelegramAdmin
)

# Стандартная модель User уже зарегистрирована в Django Admin


# ============================================
# КАСТОМНЫЙ ADMIN SITE С ГРУППИРОВКОЙ
# ============================================

class CustomAdminSite(AdminSite):
    """Кастомный AdminSite с группировкой моделей по категориям."""
    
    def get_urls(self):
        """Добавляем кастомные URL для управления БД."""
        from django.urls import path
        from .db_admin_views import (
            db_overview, db_table_view, db_backup_create,
            db_backups_list, db_backup_download, db_backup_restore
        )
        
        urls = super().get_urls()
        custom_urls = [
            path('db/', db_overview, name='db_overview'),
            path('db/table/<str:table_name>/', db_table_view, name='db_table_view'),
            path('db/backups/', db_backups_list, name='db_backups'),
            path('db/backup/create/', db_backup_create, name='db_backup_create'),
            path('db/backup/download/<str:filename>/', db_backup_download, name='db_backup_download'),
            path('db/backup/restore/', db_backup_restore, name='db_backup_restore'),
        ]
        return custom_urls + urls
    
    def get_app_list(self, request):
        """
        Возвращает список приложений с группировкой моделей по категориям.
        """
        app_dict = {}
        
        # Получаем стандартный список приложений
        for model, model_admin in self._registry.items():
            app_label = model._meta.app_label
            model_name = model._meta.model_name
            
            # Определяем категорию для каждой модели
            category = self._get_model_category(model)
            
            # Используем категорию как app_label для группировки
            category_label = category.lower().replace(' ', '_')
            
            if category_label not in app_dict:
                app_dict[category_label] = {
                    'name': category,
                    'app_label': category_label,
                    'app_url': '',
                    'has_module_perms': True,
                    'models': []
                }
            
            # Добавляем модель в соответствующую категорию
            model_info = {
                'name': model._meta.verbose_name_plural or model._meta.verbose_name,
                'object_name': model._meta.object_name,
                'perms': model_admin.get_model_perms(request),
                'admin_url': None,
                'add_url': None,
            }
            
            if model_admin.has_view_permission(request):
                model_info['admin_url'] = f'/admin/{app_label}/{model_name}/'
            if model_admin.has_add_permission(request):
                model_info['add_url'] = f'/admin/{app_label}/{model_name}/add/'
            
            app_dict[category_label]['models'].append(model_info)
        
        # Добавляем стандартные приложения Django (auth, sessions и т.д.)
        # Получаем их из стандартного admin.site
        standard_apps = {}
        for model, model_admin in admin.site._registry.items():
            app_label = model._meta.app_label
            if app_label not in ['core']:  # Исключаем core, т.к. мы его обработали отдельно
                if app_label not in standard_apps:
                    standard_apps[app_label] = {
                        'name': apps.get_app_config(app_label).verbose_name if apps.is_installed(app_label) else app_label.title(),
                        'app_label': app_label,
                        'app_url': '',
                        'has_module_perms': True,
                        'models': []
                    }
                
                model_info = {
                    'name': model._meta.verbose_name_plural or model._meta.verbose_name,
                    'object_name': model._meta.object_name,
                    'perms': model_admin.get_model_perms(request),
                    'admin_url': None,
                    'add_url': None,
                }
                
                if model_admin.has_view_permission(request):
                    model_info['admin_url'] = f'/admin/{app_label}/{model._meta.model_name}/'
                if model_admin.has_add_permission(request):
                    model_info['add_url'] = f'/admin/{app_label}/{model._meta.model_name}/add/'
                
                standard_apps[app_label]['models'].append(model_info)
        
        # Добавляем раздел "Управление БД"
        if request.user.is_staff:
            db_management = {
                'name': 'Управление БД',
                'app_label': 'db_management',
                'app_url': '/admin/db/',
                'has_module_perms': True,
                'models': [
                    {
                        'name': 'Обзор БД',
                        'object_name': 'DatabaseOverview',
                        'perms': {'view': True},
                        'admin_url': '/admin/db/',
                        'add_url': None,
                    },
                    {
                        'name': 'Бэкапы',
                        'object_name': 'DatabaseBackups',
                        'perms': {'view': True},
                        'admin_url': '/admin/db/backups/',
                        'add_url': None,
                    },
                ]
            }
            app_dict['db_management'] = db_management
        
        # Объединяем кастомные категории и стандартные приложения
        result = list(app_dict.values())
        result.extend(list(standard_apps.values()))
        
        # Сортируем по имени
        result.sort(key=lambda x: x['name'])
        
        return result
    
    def _get_model_category(self, model):
        """Определяет категорию модели."""
        model_name = model.__name__
        
        # Контент сайта
        if model_name in ['Story', 'MenuItem', 'MenuItemCategory', 'ContentSection', 'FooterSection']:
            return 'Контент сайта'
        
        # Главная страница
        elif model_name in ['HeroImage', 'HeroButton', 'HeroSettings']:
            return 'Главная страница'
        
        # Настройки сайта
        elif model_name in ['Settings', 'Translation']:
            return 'Настройки сайта'
        
        # Заказы
        elif model_name in ['Order', 'OrderItem']:
            return 'Заказы'
        
        # Личный кабинет и корзина
        elif model_name in ['Customer', 'Cart', 'CartItem', 'Favorite', 'DeliverySettings']:
            return 'Личный кабинет и корзина'
        
        # ТТК блюд
        elif model_name in ['DishTTK', 'TTKVersionHistory']:
            return 'ТТК блюд'
        
        # Интеграции
        elif model_name in ['InstagramPost', 'TelegramAdminBotSettings', 'TelegramAdmin']:
            return 'Интеграции'
        
        # Другое (вспомогательные модели - переводы и т.д.)
        else:
            # Определяем по связанной модели
            if 'Translation' in model_name:
                if 'Story' in model_name:
                    return 'Контент сайта'
                elif 'MenuItem' in model_name or 'Category' in model_name:
                    return 'Контент сайта'
                elif 'ContentSection' in model_name:
                    return 'Контент сайта'
                elif 'FooterSection' in model_name:
                    return 'Контент сайта'
            elif 'Image' in model_name or 'Attribute' in model_name:
                return 'Контент сайта'
            return 'Другое'


# Создаем экземпляр кастомного AdminSite
custom_admin_site = CustomAdminSite(name='custom_admin')

# Переопределяем стандартный admin.site для использования кастомного
# Но сначала нужно зарегистрировать все модели в custom_admin_site


# ============================================
# ГРУППА: КОНТЕНТ САЙТА
# ============================================
# Включает: Истории, Блюда меню, Разделы контента, Секции футера

class StoryForm(forms.ModelForm):
    """Форма для историй с поддержкой Markdown."""
    class Meta:
        model = Story
        fields = '__all__'
        widgets = {
            'content': forms.Textarea(attrs={
                'rows': 20,
                'cols': 80,
                'style': 'font-family: monospace; font-size: 13px;',
            }),
        }
        help_texts = {
            'content': 'Поддерживается форматирование Markdown: заголовки (# ## ###), списки (- *), жирный текст (**текст**), курсив (*текст*), ссылки, и т.д.',
        }


class StoryTranslationForm(forms.ModelForm):
    """Форма для переводов историй с поддержкой Markdown."""
    class Meta:
        model = StoryTranslation
        fields = '__all__'
        widgets = {
            'content': forms.Textarea(attrs={
                'rows': 20,
                'cols': 80,
                'style': 'font-family: monospace; font-size: 13px;',
            }),
        }
        help_texts = {
            'content': 'Поддерживается форматирование Markdown: заголовки (# ## ###), списки (- *), жирный текст (**текст**), курсив (*текст*), ссылки, и т.д.',
        }


class StoryTranslationInline(admin.TabularInline):
    """Inline для переводов историй."""
    model = StoryTranslation
    form = StoryTranslationForm
    extra = 1
    fields = ['locale', 'title', 'slug', 'excerpt', 'content']
    prepopulated_fields = {'slug': ('title',)}


class StoryAdmin(admin.ModelAdmin):
    """Админка для историй."""
    form = StoryForm
    list_display = ['title', 'slug', 'date', 'source', 'published', 'created_at', 'cover_preview']
    list_filter = ['source', 'published', 'date']
    search_fields = ['title', 'slug', 'content']
    prepopulated_fields = {'slug': ('title',)}
    readonly_fields = ['created_at', 'updated_at', 'cover_preview', 'cover_info']
    inlines = [StoryTranslationInline]
    fieldsets = (
        ('Основная информация (базовая)', {
            'fields': ('title', 'slug', 'date', 'excerpt', 'content'),
            'description': 'Эти поля используются как fallback, если нет перевода для нужной локали. Поле "Содержание" поддерживает форматирование Markdown: заголовки (# ## ###), списки (- *), жирный текст (**текст**), курсив (*текст*), ссылки, и т.д.'
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
    fields = ['locale', 'name', 'description']


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


class StockInline(admin.StackedInline):
    """Inline для остатков на складе."""
    model = Stock
    extra = 0
    max_num = 1
    fields = ['home_kitchen_quantity', 'delivery_kitchen_quantity']
    verbose_name = 'Остатки на складе'
    verbose_name_plural = 'Остатки на складе'


class MenuItemIngredientInline(admin.TabularInline):
    """Inline для ингредиентов блюда."""
    model = MenuItemIngredient
    extra = 1
    fields = ['ingredient', 'quantity']
    autocomplete_fields = ['ingredient']
    verbose_name_plural = 'Атрибуты'


# ============================================
# КАТЕГОРИИ БЛЮД
# ============================================

class MenuItemCategoryTranslationInline(admin.TabularInline):
    """Inline для переводов категорий блюд."""
    model = MenuItemCategoryTranslation
    extra = 1
    fields = ['locale', 'name', 'description']
    verbose_name = 'Перевод'
    verbose_name_plural = 'Переводы'
    fk_name = 'category'  # Явно указываем имя ForeignKey поля


class MenuItemCategoryAdmin(admin.ModelAdmin):
    """Админка для категорий блюд."""
    list_display = ['id', 'get_name', 'order_id', 'active', 'created_at']
    list_filter = ['active']
    search_fields = ['translations__name']
    list_editable = ['order_id', 'active']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [MenuItemCategoryTranslationInline]
    fieldsets = (
        ('Настройки', {
            'fields': ('order_id', 'active'),
            'description': 'Порядок отображения определяет последовательность категорий на странице заказа.'
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_name(self, obj):
        """Получить название категории из переводов."""
        first_translation = obj.translations.first()
        if first_translation:
            return first_translation.name
        return f'Категория #{obj.id}'
    get_name.short_description = 'Название'


class MenuItemAdminForm(forms.ModelForm):
    """Форма для блюд с поддержкой HTML в описании."""
    class Meta:
        model = MenuItem
        fields = '__all__'
        widgets = {
            'description': forms.Textarea(attrs={'rows': 4, 'cols': 40}),
        }


class MenuItemAdmin(admin.ModelAdmin):
    """Админка для блюд меню - Контент сайта."""
    """Админка для блюд меню."""
    form = MenuItemAdminForm
    list_display = ['name', 'category', 'price', 'order', 'active', 'created_at']
    list_filter = ['category', 'active']
    search_fields = ['name', 'description']
    list_editable = ['order', 'active']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [MenuItemTranslationInline, MenuItemImageInline, MenuItemAttributeInline, StockInline, MenuItemIngredientInline]
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
# ГРУППА: ГЛАВНАЯ СТРАНИЦА (HERO КАРУСЕЛЬ)
# ============================================
# Включает: Изображения для карусели, Настройки карусели
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


class HeroButtonTranslationInline(admin.TabularInline):
    """Inline для переводов кнопок Hero."""
    model = HeroButtonTranslation
    extra = 1
    fields = ['locale', 'text']
    verbose_name = 'Перевод'
    verbose_name_plural = 'Переводы'


class HeroButtonAdmin(admin.ModelAdmin):
    """Админка для кнопок Hero."""
    list_display = ['id', 'order', 'text_preview', 'url', 'style', 'active', 'open_in_new_tab', 'created_at']
    list_display_links = ['id']
    list_filter = ['active', 'style', 'open_in_new_tab', 'created_at']
    list_editable = ['order', 'active', 'open_in_new_tab']
    search_fields = ['url']
    inlines = [HeroButtonTranslationInline]
    fieldsets = (
        ('Основная информация', {
            'fields': ('order', 'url', 'style', 'active', 'open_in_new_tab')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    readonly_fields = ['created_at', 'updated_at']
    
    def text_preview(self, obj):
        """Показываем текст кнопки из первого перевода."""
        first_translation = obj.translations.first()
        if first_translation:
            return first_translation.text
        return '—'
    text_preview.short_description = 'Текст кнопки'


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


# Модели Hero регистрируются в custom_admin_site в конце файла


# ============================================
# ГРУППА: НАСТРОЙКИ САЙТА
# ============================================
# Включает: Основные настройки сайта, Переводы интерфейса

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


# ============================================
# ГРУППА: ЗАКАЗЫ
# ============================================
# Включает: Заказы, Элементы заказов

class OrderAdminForm(forms.ModelForm):
    """Кастомная форма для заказа с однострочными полями."""
    name = forms.CharField(
        max_length=255,
        required=False,
        widget=forms.TextInput(attrs={'class': 'vTextField'}),
        label='Имя'
    )
    email = forms.EmailField(
        max_length=255,
        required=False,
        widget=forms.EmailInput(attrs={'class': 'vTextField'}),
        label='Email'
    )
    phone = forms.CharField(
        max_length=50,
        required=False,
        widget=forms.TextInput(attrs={'class': 'vTextField'}),
        label='Телефон'
    )
    
    class Meta:
        model = Order
        fields = '__all__'


class OrderAdmin(admin.ModelAdmin):
    """Админка для заказов."""
    form = OrderAdminForm
    list_display = ['id', 'customer', 'name', 'email_display', 'phone_display', 'delivery_type_display', 'delivery_cost', 'status', 'created_at']
    list_filter = ['status', 'is_pickup', 'created_at']
    search_fields = ['name', 'email', 'phone', 'comment', 'postal_code']
    readonly_fields = ['created_at', 'updated_at', 'email_display', 'phone_display', 'total_display', 'delivery_type_display']
    inlines = [OrderItemInline]
    fieldsets = (
        ('Статус заказа', {
            'fields': ('status',)
        }),
        ('Тип доставки', {
            'fields': ('is_pickup', 'delivery_type_display'),
            'description': 'Тип получения заказа: самовывоз или доставка'
        }),
        ('Клиент', {
            'fields': ('customer', 'name', 'email', 'email_display', 'phone', 'phone_display')
        }),
        ('Адрес доставки', {
            'fields': ('postal_code', 'address', 'delivery_cost', 'delivery_distance'),
            'classes': ('collapse',)
        }),
        ('Информация о заказе', {
            'fields': ('comment', 'total_display'),
            'classes': ('collapse',)
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
    
    def email_display(self, obj):
        """Отображение маскированного email."""
        if obj.customer:
            return obj.customer.get_email_display()
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
    email_display.short_description = 'Email'
    
    def phone_display(self, obj):
        """Отображение маскированного телефона."""
        if obj.customer:
            return obj.customer.get_phone_display()
        if obj.phone and len(obj.phone) > 4:
            return obj.phone[:2] + '*' * (len(obj.phone) - 4) + obj.phone[-2:]
        return obj.phone
    phone_display.short_description = 'Телефон'
    
    def total_display(self, obj):
        """Отображение общей стоимости заказа."""
        return f'{obj.get_total():.2f}€'
    total_display.short_description = 'Общая стоимость'
    
    def delivery_type_display(self, obj):
        """Отображение типа доставки."""
        if obj.is_pickup:
            return '🚶 Самовывоз'
        else:
            return '🚚 Доставка'
    delivery_type_display.short_description = 'Тип доставки'


class OrderReviewAdmin(admin.ModelAdmin):
    """Админка для отзывов на заказы."""
    list_display = ['id', 'order', 'rating', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['order__id', 'comment']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Заказ', {
            'fields': ('order',)
        }),
        ('Отзыв', {
            'fields': ('rating', 'comment')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


# ============================================
# ГРУППА: ИНТЕГРАЦИИ
# ============================================
# Включает: Instagram посты

class InstagramPostAdmin(admin.ModelAdmin):
    """Админка для Instagram постов."""
    list_display = ['instagram_id', 'media_type', 'timestamp', 'created_at']
    list_filter = ['media_type', 'timestamp']
    search_fields = ['caption', 'instagram_id']
    readonly_fields = ['created_at', 'updated_at']


class TranslationAdmin(admin.ModelAdmin):
    """Админка для переводов - Настройки сайта."""
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


# ============================================
# ГРУППА: КОНТЕНТ САЙТА (продолжение)
# ============================================

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


class FooterSectionAdmin(admin.ModelAdmin):
    """Админка для секций футера - Контент сайта."""
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
# ГРУППА: ТТК БЛЮД (ТЕХНИКО-ТЕХНОЛОГИЧЕСКИЕ КАРТЫ)
# ============================================
# Включает: ТТК блюд, История версий ТТК
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
        from django.conf import settings
        if settings.TTK_USE_GIT:
            # Показываем информацию о Git
            if obj:
                repo = obj.get_git_repo()
                file_name = obj.get_file_name()
                if repo.file_exists(obj.menu_item.id, obj.menu_item.name):
                    return format_html(
                        '<strong>Git:</strong> {}<br><small>Путь: {}</small>',
                        file_name,
                        repo.get_file_path(obj.menu_item.id, obj.menu_item.name)
                    )
                return 'Файл не найден в Git'
            return 'Файл не загружен'
        else:
            # Старый способ через FileField
            if obj and obj.ttk_file:
                file_name = obj.get_file_name()
                file_url = obj.ttk_file.url if obj.ttk_file else None
                if file_url:
                    return format_html('<a href="{}" target="_blank">{}</a>', file_url, file_name)
                return file_name
            return 'Файл не загружен'
    file_preview.short_description = 'Файл ТТК'


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


# ============================================
# ГРУППА: ЛИЧНЫЙ КАБИНЕТ И КОРЗИНА
# ============================================
# Включает: Клиенты, Корзины, Избранное, Настройки доставки

class CustomerAdmin(admin.ModelAdmin):
    """Админка для клиентов."""
    list_display = ['id', 'name', 'email_display', 'phone_display', 'is_registered', 'email_verified', 'created_at']
    list_filter = ['is_registered', 'email_verified', 'created_at']
    search_fields = ['name', 'email', 'phone']
    readonly_fields = ['created_at', 'updated_at', 'last_login', 'email_display', 'phone_display']
    fieldsets = (
        ('Основная информация', {
            'fields': ('user', 'name', 'email', 'email_display', 'phone', 'phone_display')
        }),
        ('Адрес', {
            'fields': ('postal_code', 'address')
        }),
        ('Статус', {
            'fields': ('is_registered', 'email_verified', 'email_verification_token')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at', 'last_login'),
            'classes': ('collapse',)
        }),
    )
    
    def email_display(self, obj):
        """Отображение маскированного email."""
        return obj.get_email_display()
    email_display.short_description = 'Email (маскированный)'
    
    def phone_display(self, obj):
        """Отображение маскированного телефона."""
        return obj.get_phone_display()
    phone_display.short_description = 'Телефон (маскированный)'


class CartItemInline(admin.TabularInline):
    """Inline для элементов корзины."""
    model = CartItem
    extra = 0
    readonly_fields = ['menu_item', 'quantity', 'created_at', 'updated_at']
    fields = ['menu_item', 'quantity', 'created_at', 'updated_at']


class CartAdmin(admin.ModelAdmin):
    """Админка для корзин."""
    list_display = ['id', 'customer', 'session_key_short', 'total_display', 'total_items_display', 'created_at']
    list_filter = ['created_at', 'updated_at']
    search_fields = ['customer__name', 'customer__email', 'session_key']
    readonly_fields = ['created_at', 'updated_at', 'total_display', 'total_items_display']
    inlines = [CartItemInline]
    fieldsets = (
        ('Информация', {
            'fields': ('customer', 'session_key')
        }),
        ('Статистика', {
            'fields': ('total_display', 'total_items_display')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def session_key_short(self, obj):
        """Короткое отображение session_key."""
        if obj.session_key:
            return obj.session_key[:20] + '...' if len(obj.session_key) > 20 else obj.session_key
        return '-'
    session_key_short.short_description = 'Сессия'
    
    def total_display(self, obj):
        """Отображение общей стоимости."""
        return f'{obj.get_total():.2f}€'
    total_display.short_description = 'Общая стоимость'
    
    def total_items_display(self, obj):
        """Отображение количества товаров."""
        return obj.get_total_items()
    total_items_display.short_description = 'Количество товаров'


class FavoriteAdmin(admin.ModelAdmin):
    """Админка для избранного."""
    list_display = ['id', 'customer', 'menu_item', 'session_key_short', 'created_at']
    list_filter = ['created_at']
    search_fields = ['customer__name', 'customer__email', 'menu_item__name', 'session_key']
    readonly_fields = ['created_at']
    
    def session_key_short(self, obj):
        """Короткое отображение session_key."""
        if obj.session_key:
            return obj.session_key[:20] + '...' if len(obj.session_key) > 20 else obj.session_key
        return '-'
    session_key_short.short_description = 'Сессия'


class DeliverySettingsAdmin(admin.ModelAdmin):
    """Админка для настроек доставки."""
    def has_add_permission(self, request):
        # Разрешаем только один экземпляр
        return not DeliverySettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False

    readonly_fields = ['updated_at']
    fieldsets = (
        ('Координаты точки доставки', {
            'fields': ('delivery_point_latitude', 'delivery_point_longitude'),
            'description': 'Координаты вашей точки доставки для расчета расстояния'
        }),
        ('Настройки стоимости доставки', {
            'fields': ('base_delivery_cost', 'cost_per_km', 'free_delivery_threshold', 'max_delivery_distance'),
            'description': 'Базовая стоимость, стоимость за км, порог бесплатной доставки, максимальное расстояние'
        }),
        ('Настройки ЛК и корзины', {
            'fields': ('cart_enabled', 'favorites_enabled', 'registration_required'),
            'description': 'Включение/выключение функций личного кабинета'
        }),
        ('Дата обновления', {
            'fields': ('updated_at',),
            'classes': ('collapse',)
        }),
    )


class StockAdmin(admin.ModelAdmin):
    """Админка для готовой продукции."""
    list_display = ['menu_item', 'home_kitchen_quantity', 'delivery_kitchen_quantity', 'total_quantity_display', 'low_stock_warning_display', 'updated_at']
    list_filter = ['updated_at']
    search_fields = ['menu_item__name']
    readonly_fields = ['created_at', 'updated_at', 'total_quantity_display', 'low_stock_warning_display']
    fieldsets = (
        ('Блюдо', {
            'fields': ('menu_item',)
        }),
        ('Остатки', {
            'fields': ('home_kitchen_quantity', 'delivery_kitchen_quantity', 'total_quantity_display', 'low_stock_warning_display'),
            'description': 'Количество порций на домашней кухне и кухне доставки'
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def total_quantity_display(self, obj):
        """Отображает общее количество порций."""
        total = obj.get_total_quantity()
        return format_html('<strong>{}</strong>', total)
    total_quantity_display.short_description = 'Всего порций'
    
    def low_stock_warning_display(self, obj):
        """Отображает предупреждение о низком остатке."""
        if obj.get_low_stock_warning(threshold=5):
            return format_html('<span style="color: red; font-weight: bold;">⚠ Низкий остаток!</span>')
        return format_html('<span style="color: green;">✓ Норма</span>')
    low_stock_warning_display.short_description = 'Статус остатка'


class IngredientStockAdmin(admin.ModelAdmin):
    """Админка для склада ингредиентов."""
    list_display = ['ingredient', 'quantity_display', 'unit_display', 'total_value_display', 'location', 'low_stock_warning_display', 'updated_at']
    list_filter = ['location', 'updated_at']
    search_fields = ['ingredient__name', 'location', 'notes']
    readonly_fields = ['created_at', 'updated_at', 'quantity_display', 'unit_display', 'total_value_display', 'low_stock_warning_display']
    autocomplete_fields = ['ingredient']
    fieldsets = (
        ('Ингредиент', {
            'fields': ('ingredient',)
        }),
        ('Остаток на складе', {
            'fields': ('quantity', 'quantity_display', 'unit_display', 'total_value_display', 'low_stock_warning_display'),
            'description': 'Количество ингредиента на складе'
        }),
        ('Место хранения', {
            'fields': ('location', 'notes'),
            'classes': ('collapse',)
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def quantity_display(self, obj):
        """Отображает количество с единицей измерения."""
        return format_html('<strong>{}</strong>', obj.quantity)
    quantity_display.short_description = 'Количество'
    
    def unit_display(self, obj):
        """Отображает единицу измерения."""
        unit_display = dict(obj.ingredient.UNIT_CHOICES).get(obj.ingredient.unit, obj.ingredient.unit)
        return unit_display
    unit_display.short_description = 'Единица измерения'
    
    def total_value_display(self, obj):
        """Отображает общую стоимость остатка."""
        value = obj.get_total_value()
        if value is not None:
            formatted_value = f'{value:.2f}€'
            return format_html('<strong>{}</strong>', formatted_value)
        return '—'
    total_value_display.short_description = 'Стоимость остатка'
    
    def low_stock_warning_display(self, obj):
        """Отображает предупреждение о низком остатке."""
        if obj.get_low_stock_warning():
            return format_html('<span style="color: red; font-weight: bold;">⚠ Низкий остаток!</span>')
        return format_html('<span style="color: green;">✓ Норма</span>')
    low_stock_warning_display.short_description = 'Статус остатка'


class SupplierAdmin(admin.ModelAdmin):
    """Админка для поставщиков."""
    list_display = ['name', 'contact_person', 'phone', 'email', 'active', 'created_at']
    list_filter = ['active', 'created_at']
    search_fields = ['name', 'contact_person', 'phone', 'email', 'address']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Основная информация', {
            'fields': ('name', 'contact_person', 'phone', 'email', 'address', 'active')
        }),
        ('Примечания', {
            'fields': ('notes',),
            'classes': ('collapse',)
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


class PriceSourceAdmin(admin.ModelAdmin):
    """Админка для источников цен."""
    list_display = ['name', 'file_format', 'active', 'last_sync', 'sync_frequency', 'ingredients_count', 'created_at']
    list_filter = ['active', 'file_format', 'created_at']
    search_fields = ['name', 'slug', 'description']
    readonly_fields = ['created_at', 'updated_at', 'last_sync', 'ingredients_count']
    prepopulated_fields = {'slug': ('name',)}
    fieldsets = (
        ('Основная информация', {
            'fields': ('name', 'slug', 'description', 'active')
        }),
        ('API настройки', {
            'fields': ('api_url', 'api_key'),
            'classes': ('collapse',)
        }),
        ('Настройки импорта', {
            'fields': ('file_format', 'sync_frequency', 'last_sync')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at', 'ingredients_count'),
            'classes': ('collapse',)
        }),
    )
    
    def ingredients_count(self, obj):
        """Количество ингредиентов с ценами из этого источника."""
        if obj.pk:
            return obj.ingredients.count()
        return 0
    ingredients_count.short_description = 'Количество ингредиентов'


class IngredientCategoryAdmin(admin.ModelAdmin):
    """Админка для категорий ингредиентов."""
    list_display = ['name', 'slug', 'order', 'ingredients_count', 'active', 'created_at']
    list_filter = ['active', 'created_at']
    search_fields = ['name', 'slug', 'description']
    readonly_fields = ['created_at', 'updated_at', 'ingredients_count']
    prepopulated_fields = {'slug': ('name',)}
    fieldsets = (
        ('Основная информация', {
            'fields': ('name', 'slug', 'description', 'order', 'active')
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at', 'ingredients_count'),
            'classes': ('collapse',)
        }),
    )
    
    def ingredients_count(self, obj):
        """Количество ингредиентов в категории."""
        if obj.pk:
            return obj.ingredients.count()
        return 0
    ingredients_count.short_description = 'Количество ингредиентов'


class IngredientAdmin(admin.ModelAdmin):
    """Админка для ингредиентов."""
    list_display = ['name', 'category', 'unit', 'price', 'quantity', 'cost_per_kg_display', 'price_source', 'price_updated_at', 'supplier', 'created_at']
    list_filter = ['category', 'unit', 'supplier', 'price_source', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['created_at', 'updated_at', 'cost_per_kg_display', 'price_updated_at']
    autocomplete_fields = ['supplier', 'category', 'price_source']
    fieldsets = (
        ('Основная информация', {
            'fields': ('name', 'category', 'unit', 'description', 'supplier')
        }),
        ('Цена и количество', {
            'fields': ('price', 'quantity', 'weight', 'cost_per_kg_display', 'price_source', 'price_updated_at'),
            'description': 'Укажите цену и количество. Для поштучных товаров укажите вес для расчета стоимости за кг.'
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def cost_per_kg_display(self, obj):
        """Отображение стоимости за килограмм."""
        cost = obj.cost_per_kg
        if cost is not None:
            return f'{cost:.2f}€/кг'
        return '—'
    cost_per_kg_display.short_description = 'Стоимость за кг'
    
    def description_preview(self, obj):
        """Превью описания."""
        if obj.description:
            return obj.description[:50] + '...' if len(obj.description) > 50 else obj.description
        return '—'
    description_preview.short_description = 'Описание'


class MenuItemIngredientAdmin(admin.ModelAdmin):
    """Админка для состава блюд."""
    list_display = ['menu_item', 'ingredient', 'quantity', 'unit_display', 'created_at']
    list_filter = ['created_at', 'ingredient']
    search_fields = ['menu_item__name', 'ingredient__name']
    readonly_fields = ['created_at', 'updated_at']
    autocomplete_fields = ['menu_item', 'ingredient']
    fieldsets = (
        ('Связь', {
            'fields': ('menu_item', 'ingredient')
        }),
        ('Количество', {
            'fields': ('quantity',),
            'description': 'Количество ингредиента на одну порцию блюда'
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def unit_display(self, obj):
        """Отображает единицу измерения ингредиента."""
        return obj.ingredient.unit
    unit_display.short_description = 'Единица измерения'


class TelegramAdminBotSettingsAdmin(admin.ModelAdmin):
    """Админка для настроек админского Telegram бота."""
    def has_add_permission(self, request):
        # Разрешаем только один экземпляр
        return not TelegramAdminBotSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False

    readonly_fields = ['updated_at']
    fieldsets = (
        ('Основные настройки', {
            'fields': ('enabled', 'bot_token'),
            'description': 'Включите бота и укажите токен от @BotFather'
        }),
        ('Уведомления', {
            'fields': (
                'notify_new_order',
                'notify_order_status_change',
                'notify_new_customer',
                'notify_review'
            ),
            'description': 'Выберите события, о которых нужно уведомлять'
        }),
        ('Ежедневные отчеты', {
            'fields': ('daily_reports_enabled', 'daily_reports_time'),
            'description': 'Настройки автоматических отчетов об остатках'
        }),
        ('Пороги для остатков блюд', {
            'fields': ('menu_item_low_stock_threshold',),
            'description': 'Минимальное количество порций для предупреждения'
        }),
        ('Пороги для остатков ингредиентов', {
            'fields': (
                'ingredient_threshold_kg',
                'ingredient_threshold_g',
                'ingredient_threshold_l',
                'ingredient_threshold_ml',
                'ingredient_threshold_pcs'
            ),
            'description': 'Пороги для разных единиц измерения ингредиентов'
        }),
        ('Настройки отображения заказов', {
            'fields': ('orders_display_statuses',),
            'description': 'Выберите статусы заказов, которые будут отображаться в разделе "Текущие заказы" бота. Статусы: pending (Ожидает), processing (Обрабатывается), completed (Завершен), cancelled (Отменен). Укажите через запятую, например: pending,processing'
        }),
        ('Дата обновления', {
            'fields': ('updated_at',),
            'classes': ('collapse',)
        }),
    )


class TelegramAdminAdmin(admin.ModelAdmin):
    """Админка для админов Telegram бота."""
    list_display = ['telegram_chat_id', 'username_display', 'authorized', 'banned', 'user', 'created_at']
    list_filter = ['authorized', 'banned', 'created_at']
    search_fields = ['user__username', 'user__email', 'telegram_chat_id', 'username', 'first_name', 'last_name']
    list_editable = ['authorized', 'banned']
    readonly_fields = ['created_at', 'updated_at', 'telegram_chat_id', 'username', 'first_name', 'last_name']
    fieldsets = (
        ('Информация о пользователе Telegram', {
            'fields': ('telegram_chat_id', 'username', 'first_name', 'last_name', 'user'),
            'description': 'Информация автоматически обновляется при команде /start'
        }),
        ('Статус доступа', {
            'fields': ('authorized', 'banned'),
            'description': '<b>Авторизован</b> - пользователь может использовать бота и получать уведомления.<br><b>Забанен</b> - пользователь заблокирован и не получит никаких сообщений от бота.'
        }),
        ('Даты', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def username_display(self, obj):
        """Отобразить имя пользователя или chat_id."""
        if obj.username:
            return f"@{obj.username}"
        name = f"{obj.first_name or ''} {obj.last_name or ''}".strip()
        return name or f"Chat {obj.telegram_chat_id}"
    username_display.short_description = 'Пользователь'
    
    def get_queryset(self, request):
        """Оптимизируем запросы."""
        return super().get_queryset(request).select_related('user')


# Регистрируем все модели в кастомном админ-сайте вместо стандартного
custom_admin_site.register(Story, StoryAdmin)
custom_admin_site.register(MenuItemCategory, MenuItemCategoryAdmin)
custom_admin_site.register(MenuItem, MenuItemAdmin)
custom_admin_site.register(HeroImage, HeroImageAdmin)
custom_admin_site.register(HeroButton, HeroButtonAdmin)
custom_admin_site.register(HeroSettings, HeroSettingsAdmin)
custom_admin_site.register(Settings, SettingsAdmin)
custom_admin_site.register(Order, OrderAdmin)
custom_admin_site.register(OrderReview, OrderReviewAdmin)
custom_admin_site.register(InstagramPost, InstagramPostAdmin)
custom_admin_site.register(Translation, TranslationAdmin)
custom_admin_site.register(ContentSection, ContentSectionAdmin)
custom_admin_site.register(FooterSection, FooterSectionAdmin)
custom_admin_site.register(DishTTK, DishTTKAdmin)
custom_admin_site.register(TTKVersionHistory, TTKVersionHistoryAdmin)
custom_admin_site.register(Customer, CustomerAdmin)
custom_admin_site.register(Cart, CartAdmin)
custom_admin_site.register(Favorite, FavoriteAdmin)
custom_admin_site.register(DeliverySettings, DeliverySettingsAdmin)
custom_admin_site.register(Stock, StockAdmin)
custom_admin_site.register(Supplier, SupplierAdmin)
custom_admin_site.register(PriceSource, PriceSourceAdmin)
custom_admin_site.register(IngredientCategory, IngredientCategoryAdmin)
custom_admin_site.register(Ingredient, IngredientAdmin)
custom_admin_site.register(IngredientStock, IngredientStockAdmin)
custom_admin_site.register(MenuItemIngredient, MenuItemIngredientAdmin)
custom_admin_site.register(TelegramAdminBotSettings, TelegramAdminBotSettingsAdmin)
custom_admin_site.register(TelegramAdmin, TelegramAdminAdmin)

