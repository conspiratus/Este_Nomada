"""
Core models for Este Nómada project.
"""
from django.db import models
from django.contrib.auth.models import User
from django.utils.text import slugify
from django.core.validators import MinValueValidator

# Используем стандартную модель User Django
# Для расширения функциональности можно использовать UserProfile


class Story(models.Model):
    """Модель для историй/постов блога."""
    SOURCE_CHOICES = [
        ('manual', 'Ручной'),
        ('telegram', 'Telegram'),
    ]

    # Базовые поля (используются как fallback, если нет перевода)
    title = models.CharField(max_length=500, verbose_name='Заголовок (базовый)')
    slug = models.SlugField(max_length=500, unique=True, verbose_name='URL (базовый)')
    date = models.DateField(verbose_name='Дата')
    excerpt = models.TextField(blank=True, null=True, verbose_name='Краткое описание (базовое)')
    content = models.TextField(verbose_name='Содержание (базовое)')
    cover_image = models.URLField(max_length=500, blank=True, null=True, verbose_name='Обложка (URL)')
    cover_image_file = models.ImageField(upload_to='stories/', blank=True, null=True, verbose_name='Обложка (загрузка файла)')
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default='manual', verbose_name='Источник')
    published = models.BooleanField(default=True, verbose_name='Опубликовано')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'stories'
        verbose_name = 'История'
        verbose_name_plural = 'Истории'
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['slug']),
            models.Index(fields=['date']),
            models.Index(fields=['published']),
        ]

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)
    
    def get_translation(self, locale: str):
        """Получить перевод для указанной локали."""
        try:
            return self.translations.get(locale=locale)
        except StoryTranslation.DoesNotExist:
            return None
    
    def get_cover_image_url(self):
        """Возвращает URL обложки: сначала из загруженного файла, затем из URL поля."""
        if self.cover_image_file and self.cover_image_file.name:
            return self.cover_image_file.url
        return self.cover_image


class StoryTranslation(models.Model):
    """Переводы для историй."""
    story = models.ForeignKey(Story, related_name='translations', on_delete=models.CASCADE, verbose_name='История')
    locale = models.CharField(max_length=10, verbose_name='Локаль')
    title = models.CharField(max_length=500, verbose_name='Заголовок')
    slug = models.SlugField(max_length=500, verbose_name='URL')
    excerpt = models.TextField(blank=True, null=True, verbose_name='Краткое описание')
    content = models.TextField(verbose_name='Содержание')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'story_translations'
        verbose_name = 'Перевод истории'
        verbose_name_plural = 'Переводы историй'
        unique_together = [['story', 'locale']]
        indexes = [
            models.Index(fields=['story', 'locale']),
            models.Index(fields=['slug']),
        ]

    def __str__(self):
        return f'{self.story.title} ({self.locale})'


class MenuItem(models.Model):
    """Модель для блюд меню."""
    # Базовые поля (используются как fallback, если нет перевода)
    name = models.CharField(max_length=255, verbose_name='Название (базовое)')
    description = models.TextField(blank=True, null=True, verbose_name='Описание (базовое)', help_text='Поддерживает HTML')
    category = models.CharField(max_length=100, verbose_name='Категория (базовая)')
    price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True, verbose_name='Цена')
    image = models.URLField(max_length=500, blank=True, null=True, verbose_name='Изображение')
    order = models.IntegerField(default=0, validators=[MinValueValidator(0)], verbose_name='Порядок')
    active = models.BooleanField(default=True, verbose_name='Активно')
    # Связь с историями
    related_stories = models.ManyToManyField('Story', blank=True, related_name='menu_items', verbose_name='Связанные истории')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'menu_items'
        verbose_name = 'Блюдо'
        verbose_name_plural = 'Блюда'
        ordering = ['order', 'name']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['active']),
            models.Index(fields=['order']),
        ]

    def __str__(self):
        return self.name
    
    def get_translation(self, locale: str):
        """Получить перевод для указанной локали."""
        try:
            return self.translations.get(locale=locale)
        except MenuItemTranslation.DoesNotExist:
            return None


class MenuItemTranslation(models.Model):
    """Переводы для блюд меню."""
    menu_item = models.ForeignKey(MenuItem, related_name='translations', on_delete=models.CASCADE, verbose_name='Блюдо')
    locale = models.CharField(max_length=10, verbose_name='Локаль')
    name = models.CharField(max_length=255, verbose_name='Название')
    description = models.TextField(blank=True, null=True, verbose_name='Описание', help_text='Поддерживает HTML')
    category = models.CharField(max_length=100, verbose_name='Категория')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'menu_item_translations'
        verbose_name = 'Перевод блюда'
        verbose_name_plural = 'Переводы блюд'
        unique_together = [['menu_item', 'locale']]
        indexes = [
            models.Index(fields=['menu_item', 'locale']),
        ]

    def __str__(self):
        return f'{self.menu_item.name} ({self.locale})'


class MenuItemImage(models.Model):
    """Изображения для блюд меню."""
    menu_item = models.ForeignKey(MenuItem, related_name='images', on_delete=models.CASCADE, verbose_name='Блюдо')
    image = models.ImageField(upload_to='menu_items/', null=True, blank=True, verbose_name='Изображение')
    image_url = models.URLField(max_length=500, blank=True, verbose_name='URL изображения')
    order = models.IntegerField(default=0, validators=[MinValueValidator(0)], verbose_name='Порядок')
    created_at = models.DateTimeField(auto_now_add=True)
    
    def get_image_url(self):
        """Возвращает URL изображения (приоритет: загруженный файл, затем URL)."""
        if self.image:
            return self.image.url
        return self.image_url

    class Meta:
        db_table = 'menu_item_images'
        verbose_name = 'Изображение блюда'
        verbose_name_plural = 'Изображения блюд'
        ordering = ['order', 'created_at']
        indexes = [
            models.Index(fields=['menu_item', 'order']),
        ]

    def __str__(self):
        return f'{self.menu_item.name} - изображение {self.order}'


class MenuItemAttribute(models.Model):
    """Динамические атрибуты для блюд меню."""
    menu_item = models.ForeignKey(MenuItem, related_name='attributes', on_delete=models.CASCADE, verbose_name='Блюдо')
    locale = models.CharField(max_length=10, verbose_name='Локаль')
    name = models.CharField(max_length=255, verbose_name='Название атрибута')
    value = models.CharField(max_length=500, verbose_name='Значение')
    order = models.IntegerField(default=0, validators=[MinValueValidator(0)], verbose_name='Порядок')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'menu_item_attributes'
        verbose_name = 'Атрибут блюда'
        verbose_name_plural = 'Атрибуты блюд'
        ordering = ['order', 'name']
        indexes = [
            models.Index(fields=['menu_item', 'locale']),
            models.Index(fields=['menu_item', 'order']),
        ]

    def __str__(self):
        return f'{self.menu_item.name} - {self.name}: {self.value} ({self.locale})'


class HeroImage(models.Model):
    """Изображения для Hero секции."""
    image = models.ImageField(upload_to='hero/', null=True, blank=True, verbose_name='Изображение (загрузка файла)')
    image_url = models.URLField(max_length=500, blank=True, verbose_name='URL изображения (альтернатива)')
    order = models.IntegerField(default=0, validators=[MinValueValidator(0)], verbose_name='Порядок')
    active = models.BooleanField(default=True, verbose_name='Активно')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'hero_images'
        verbose_name = 'Hero изображение'
        verbose_name_plural = 'Hero изображения'
        ordering = ['order', 'created_at']
        indexes = [
            models.Index(fields=['active', 'order']),
        ]
        # Группируем в админке
        app_label = 'core'

    def __str__(self):
        return f'Hero изображение {self.order}'


class HeroSettings(models.Model):
    """Настройки Hero секции."""
    
    TRANSITION_CHOICES = [
        ('crossfade', 'Плавное растворение (Crossfade)'),
        ('fade', 'Исчезновение и появление (Fade)'),
        ('slide', 'Слайд (Slide)'),
    ]
    
    slide_interval = models.IntegerField(
        default=5000,
        validators=[MinValueValidator(1000)],
        verbose_name='Интервал переключения (мс)',
        help_text='Время в миллисекундах между переключениями слайдов'
    )
    transition_effect = models.CharField(
        max_length=20,
        choices=TRANSITION_CHOICES,
        default='crossfade',
        verbose_name='Эффект перехода',
        help_text='Эффект анимации при смене слайдов'
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'hero_settings'
        verbose_name = 'Настройки Hero'
        verbose_name_plural = 'Настройки Hero'
        # Группируем в админке
        app_label = 'core'

    def __str__(self):
        return f'Hero настройки (интервал: {self.slide_interval}мс, эффект: {self.get_transition_effect_display()})'

    def save(self, *args, **kwargs):
        # Разрешаем только один экземпляр
        self.pk = 1
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        # Не позволяем удалять настройки
        pass


class Settings(models.Model):
    """Модель для настроек сайта."""
    site_name = models.CharField(max_length=255, default='Este Nómada', verbose_name='Название сайта')
    logo = models.ImageField(upload_to='settings/', null=True, blank=True, verbose_name='Логотип сайта')
    site_description = models.TextField(blank=True, null=True, verbose_name='Описание сайта')
    contact_email = models.EmailField(blank=True, null=True, verbose_name='Email для контактов')
    telegram_channel = models.URLField(blank=True, null=True, verbose_name='Telegram канал')
    bot_token = models.CharField(max_length=255, blank=True, null=True, verbose_name='Telegram Bot Token')
    channel_id = models.CharField(max_length=255, blank=True, null=True, verbose_name='Telegram Channel ID')
    auto_sync = models.BooleanField(default=False, verbose_name='Автосинхронизация')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'settings'
        verbose_name = 'Настройки'
        verbose_name_plural = 'Настройки'

    def __str__(self):
        return self.site_name

    @classmethod
    def get_settings(cls):
        """Получить единственный экземпляр настроек."""
        obj, created = cls.objects.get_or_create(pk=1)
        return obj


class Order(models.Model):
    """Модель для заказов."""
    STATUS_CHOICES = [
        ('pending', 'Ожидает обработки'),
        ('processing', 'Обрабатывается'),
        ('completed', 'Завершен'),
        ('cancelled', 'Отменен'),
    ]

    name = models.CharField(max_length=255, verbose_name='Имя')
    phone = models.CharField(max_length=50, verbose_name='Телефон')
    comment = models.TextField(blank=True, null=True, verbose_name='Комментарий')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', verbose_name='Статус')
    ai_response = models.TextField(blank=True, null=True, verbose_name='Ответ AI')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'orders'
        verbose_name = 'Заказ'
        verbose_name_plural = 'Заказы'
        ordering = ['-created_at']

    def __str__(self):
        return f'Заказ #{self.id} от {self.name}'

    def get_selected_dishes(self):
        """Получить выбранные блюда."""
        return self.order_items.all()


class OrderItem(models.Model):
    """Модель для элементов заказа."""
    order = models.ForeignKey(Order, related_name='order_items', on_delete=models.CASCADE, verbose_name='Заказ')
    menu_item = models.ForeignKey(MenuItem, on_delete=models.CASCADE, verbose_name='Блюдо')
    quantity = models.IntegerField(default=1, validators=[MinValueValidator(1)], verbose_name='Количество')

    class Meta:
        db_table = 'order_items'
        verbose_name = 'Элемент заказа'
        verbose_name_plural = 'Элементы заказа'

    def __str__(self):
        return f'{self.menu_item.name} x{self.quantity}'


class InstagramPost(models.Model):
    """Модель для постов из Instagram."""
    instagram_id = models.CharField(max_length=255, unique=True, verbose_name='Instagram ID')
    caption = models.TextField(blank=True, null=True, verbose_name='Подпись')
    media_url = models.URLField(max_length=500, verbose_name='URL медиа')
    media_type = models.CharField(max_length=50, verbose_name='Тип медиа')
    permalink = models.URLField(max_length=500, verbose_name='Ссылка')
    timestamp = models.DateTimeField(verbose_name='Дата публикации')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'instagram_posts'
        verbose_name = 'Instagram пост'
        verbose_name_plural = 'Instagram посты'
        ordering = ['-timestamp']

    def __str__(self):
        return f'Instagram Post {self.instagram_id}'


class Translation(models.Model):
    """Модель для переводов интерфейса."""
    locale = models.CharField(max_length=10, verbose_name='Локаль')
    namespace = models.CharField(max_length=100, verbose_name='Пространство имён')
    key = models.CharField(max_length=255, verbose_name='Ключ')
    value = models.TextField(verbose_name='Значение')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'translations'
        verbose_name = 'Перевод'
        verbose_name_plural = 'Переводы'
        unique_together = [['locale', 'namespace', 'key']]
        indexes = [
            models.Index(fields=['locale', 'namespace']),
        ]

    def __str__(self):
        return f'{self.locale}/{self.namespace}.{self.key}'


class ContentSection(models.Model):
    """Универсальная модель для разделов контента."""
    SECTION_TYPE_CHOICES = [
        ('about', 'О нас'),
        ('hero', 'Главный экран'),
        ('services', 'Услуги'),
        ('features', 'Особенности'),
        ('testimonials', 'Отзывы'),
        ('team', 'Команда'),
        ('custom', 'Пользовательский'),
    ]
    
    section_type = models.CharField(max_length=50, choices=SECTION_TYPE_CHOICES, default='custom', verbose_name='Тип раздела')
    section_id = models.CharField(max_length=100, unique=True, verbose_name='ID раздела (для ссылок)')
    
    # Базовые поля (используются как fallback, если нет перевода)
    title = models.CharField(max_length=200, verbose_name='Заголовок (базовый)')
    subtitle = models.CharField(max_length=300, blank=True, verbose_name='Подзаголовок (базовый)')
    description = models.TextField(verbose_name='Описание (базовое)', help_text='Поддерживает HTML')
    content = models.TextField(blank=True, verbose_name='Дополнительный контент (базовый)', help_text='Поддерживает HTML')
    
    # Медиа
    image = models.ImageField(upload_to='sections/', null=True, blank=True, verbose_name='Изображение')
    image_url = models.URLField(max_length=500, blank=True, verbose_name='URL изображения')
    
    # Настройки отображения
    order = models.IntegerField(default=0, validators=[MinValueValidator(0)], verbose_name='Порядок')
    published = models.BooleanField(default=True, verbose_name='Опубликовано')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'content_sections'
        verbose_name = 'Раздел контента'
        verbose_name_plural = 'Разделы контента'
        ordering = ['section_type', 'order']
        indexes = [
            models.Index(fields=['section_type', 'published']),
            models.Index(fields=['section_id']),
        ]

    def __str__(self):
        return f'{self.get_section_type_display()}: {self.title}'
    
    def get_translation(self, locale: str):
        """Получить перевод для указанной локали."""
        try:
            return self.translations.get(locale=locale)
        except ContentSectionTranslation.DoesNotExist:
            return None


class ContentSectionTranslation(models.Model):
    """Переводы для разделов контента."""
    section = models.ForeignKey(ContentSection, related_name='translations', on_delete=models.CASCADE, verbose_name='Раздел')
    locale = models.CharField(max_length=10, verbose_name='Локаль')
    title = models.CharField(max_length=200, verbose_name='Заголовок')
    subtitle = models.CharField(max_length=300, blank=True, verbose_name='Подзаголовок')
    description = models.TextField(verbose_name='Описание', help_text='Поддерживает HTML')
    content = models.TextField(blank=True, verbose_name='Дополнительный контент')
    
    class Meta:
        db_table = 'content_section_translations'
        verbose_name = 'Перевод раздела контента'
        verbose_name_plural = 'Переводы разделов контента'
        unique_together = [['section', 'locale']]
    
    def __str__(self):
        return f'{self.section.title} ({self.locale})'


# Для обратной совместимости
AboutSection = ContentSection
AboutSectionTranslation = ContentSectionTranslation


class FooterSection(models.Model):
    """Модель для секций футера."""
    POSITION_CHOICES = [
        ('left', 'Слева'),
        ('center', 'По центру'),
        ('right', 'Справа'),
    ]
    
    TEXT_ALIGN_CHOICES = [
        ('left', 'По левому краю'),
        ('center', 'По центру'),
        ('right', 'По правому краю'),
        ('justify', 'По ширине'),
    ]
    
    title = models.CharField(max_length=200, verbose_name='Заголовок', help_text='Поддерживает HTML')
    content = models.TextField(verbose_name='Содержимое', help_text='Поддерживает HTML')
    position = models.CharField(
        max_length=10, 
        choices=POSITION_CHOICES, 
        default='left',
        verbose_name='Позиция в футере'
    )
    text_align = models.CharField(
        max_length=10,
        choices=TEXT_ALIGN_CHOICES,
        default='left',
        verbose_name='Выравнивание текста'
    )
    order = models.IntegerField(default=0, validators=[MinValueValidator(0)], verbose_name='Порядок')
    published = models.BooleanField(default=True, verbose_name='Опубликовано')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'footer_sections'
        verbose_name = 'Секция футера'
        verbose_name_plural = 'Секции футера'
        ordering = ['position', 'order']
        indexes = [
            models.Index(fields=['position', 'order']),
            models.Index(fields=['published']),
        ]
    
    def __str__(self):
        return f'{self.get_position_display()}: {self.title}'


class FooterSectionTranslation(models.Model):
    """Переводы для секций футера."""
    section = models.ForeignKey(FooterSection, related_name='translations', on_delete=models.CASCADE, verbose_name='Секция')
    locale = models.CharField(max_length=10, verbose_name='Локаль')
    title = models.CharField(max_length=200, verbose_name='Заголовок', help_text='Поддерживает HTML')
    content = models.TextField(verbose_name='Содержимое', help_text='Поддерживает HTML')
    
    class Meta:
        db_table = 'footer_section_translations'
        verbose_name = 'Перевод секции футера'
        verbose_name_plural = 'Переводы секций футера'
        unique_together = [['section', 'locale']]
    
    def __str__(self):
        return f'{self.section.title} ({self.locale})'


class DishTTK(models.Model):
    """Модель для технико-технологических карт (ТТК) блюд."""
    menu_item = models.OneToOneField(
        MenuItem,
        on_delete=models.CASCADE,
        related_name='ttk',
        verbose_name='Блюдо',
        help_text='Выберите блюдо, для которого создается ТТК'
    )
    ttk_file = models.FileField(
        upload_to='ttk/',
        verbose_name='Файл ТТК (.md)',
        help_text='Загрузите файл технико-технологической карты в формате Markdown (.md)',
        blank=True,
        null=True
    )
    version = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name='Версия ТТК',
        help_text='Номер или название версии ТТК (например: 1.0, 2024-01)'
    )
    notes = models.TextField(
        blank=True,
        null=True,
        verbose_name='Примечания',
        help_text='Дополнительные заметки о ТТК'
    )
    active = models.BooleanField(
        default=True,
        verbose_name='Активна',
        help_text='Активна ли данная версия ТТК'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Дата обновления')

    class Meta:
        db_table = 'dish_ttk'
        verbose_name = 'ТТК блюда'
        verbose_name_plural = 'ТТК блюд'
        ordering = ['-updated_at', '-created_at']
        indexes = [
            models.Index(fields=['menu_item']),
            models.Index(fields=['active']),
        ]

    def __str__(self):
        version_str = f' (v{self.version})' if self.version else ''
        return f'ТТК: {self.menu_item.name}{version_str}'
    
    def get_file_name(self):
        """Возвращает имя файла без пути."""
        from django.conf import settings
        if settings.TTK_USE_GIT:
            from .git_utils import TTKGitRepository
            repo = TTKGitRepository(settings.TTK_GIT_REPO_PATH)
            file_path = repo.get_file_path(self.menu_item.id, self.menu_item.name)
            return file_path.name
        elif self.ttk_file:
            return self.ttk_file.name.split('/')[-1]
        return None
    
    def get_git_repo(self):
        """Возвращает экземпляр Git репозитория для работы с ТТК."""
        from django.conf import settings
        from .git_utils import TTKGitRepository
        return TTKGitRepository(
            settings.TTK_GIT_REPO_PATH,
            settings.TTK_GIT_USER_NAME,
            settings.TTK_GIT_USER_EMAIL
        )


class TTKVersionHistory(models.Model):
    """Модель для истории версий ТТК."""
    ttk = models.ForeignKey(
        DishTTK,
        on_delete=models.CASCADE,
        related_name='version_history',
        verbose_name='ТТК',
        help_text='ТТК, к которой относится версия'
    )
    version = models.CharField(
        max_length=50,
        verbose_name='Версия',
        help_text='Номер или название версии'
    )
    content = models.TextField(
        verbose_name='Содержимое ТТК',
        help_text='Содержимое файла ТТК на момент создания версии'
    )
    changed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='ttk_versions',
        verbose_name='Изменено пользователем'
    )
    change_description = models.TextField(
        blank=True,
        null=True,
        verbose_name='Описание изменений',
        help_text='Описание того, что было изменено в этой версии'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Дата создания версии')

    class Meta:
        db_table = 'ttk_version_history'
        verbose_name = 'История версий ТТК'
        verbose_name_plural = 'История версий ТТК'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['ttk', '-created_at']),
        ]

    def __str__(self):
        return f'Версия {self.version} ТТК: {self.ttk.menu_item.name}'

