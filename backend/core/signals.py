"""
Сигналы Django для автоматической обработки изображений.
"""
import logging
from django.conf import settings
from django.db.models.signals import pre_save
from django.dispatch import receiver
from .models import MenuItemImage, ContentSection, Settings, HeroImage, Story
from .utils import optimize_image

logger = logging.getLogger(__name__)


def should_optimize_image(instance, model_class, field_name='image'):
    """
    Проверяет, нужно ли оптимизировать изображение.
    
    Args:
        instance: Экземпляр модели
        model_class: Класс модели
        field_name: Имя поля с изображением ('image' или 'logo')
    
    Returns:
        bool: True если нужно оптимизировать, False если пропустить
    """
    # Проверяем, включена ли оптимизация
    if not getattr(settings, 'IMAGE_OPTIMIZATION', {}).get('ENABLED', True):
        return False
    
    # Получаем поле изображения
    image_field = getattr(instance, field_name, None)
    
    # Если нет изображения, пропускаем
    if not image_field or not image_field.name:
        return False
    
    # Если это новый объект, всегда оптимизируем
    if not instance.pk:
        return True
    
    # Для существующих объектов проверяем, изменилось ли изображение
    try:
        old_instance = model_class.objects.get(pk=instance.pk)
        old_image_field = getattr(old_instance, field_name, None)
        old_name = old_image_field.name if old_image_field and old_image_field.name else None
        
        # Если имя файла изменилось, значит загружено новое изображение
        if old_name != image_field.name:
            return True
        # Если имя не изменилось, но файл был перезаписан (проверяем по наличию file)
        if hasattr(image_field, 'file') and image_field.file:
            return True
    except model_class.DoesNotExist:
        return True
    
    return False


@receiver(pre_save, sender=MenuItemImage)
def optimize_menu_item_image(sender, instance, **kwargs):
    """
    Оптимизирует изображение блюда перед сохранением.
    """
    if not should_optimize_image(instance, MenuItemImage):
        return
    
    config = getattr(settings, 'IMAGE_OPTIMIZATION', {})
    logger.info(f"[ImageOptimization] Optimizing menu item image: {instance.image.name}")
    
    # Для изображений меню используем меньший размер, так как они отображаются в карточках
    optimize_image(
        instance.image,
        max_width=800,  # Уменьшено с 1920 для карточек меню
        max_height=800,
        quality=config.get('QUALITY', 85),
        format=config.get('FORMAT', 'WEBP')
    )


@receiver(pre_save, sender=ContentSection)
def optimize_content_section_image(sender, instance, **kwargs):
    """
    Оптимизирует изображение раздела контента перед сохранением.
    """
    if not should_optimize_image(instance, ContentSection):
        return
    
    config = getattr(settings, 'IMAGE_OPTIMIZATION', {})
    logger.info(f"[ImageOptimization] Optimizing content section image: {instance.image.name}")
    
    optimize_image(
        instance.image,
        max_width=config.get('MAX_WIDTH', 1920),
        max_height=config.get('MAX_HEIGHT', 1920),
        quality=config.get('QUALITY', 85),
        format=config.get('FORMAT', 'WEBP')
    )


@receiver(pre_save, sender=Settings)
def optimize_settings_logo(sender, instance, **kwargs):
    """
    Оптимизирует логотип сайта перед сохранением.
    """
    if not should_optimize_image(instance, Settings, field_name='logo'):
        return
    
    config = getattr(settings, 'IMAGE_OPTIMIZATION', {})
    logger.info(f"[ImageOptimization] Optimizing settings logo: {instance.logo.name}")
    
    optimize_image(
        instance.logo,
        max_width=512,  # Логотип обычно меньше
        max_height=512,
        quality=config.get('QUALITY', 85),
        format=config.get('FORMAT', 'WEBP')
    )


@receiver(pre_save, sender=HeroImage)
def optimize_hero_image(sender, instance, **kwargs):
    """
    Оптимизирует изображение Hero перед сохранением.
    """
    if not should_optimize_image(instance, HeroImage, field_name='image'):
        return
    
    config = getattr(settings, 'IMAGE_OPTIMIZATION', {})
    logger.info(f"[ImageOptimization] Optimizing hero image: {instance.image.name}")
    
    optimize_image(
        instance.image,
        max_width=config.get('MAX_WIDTH', 1920),
        max_height=config.get('MAX_HEIGHT', 1920),
        quality=config.get('QUALITY', 85),
        format=config.get('FORMAT', 'WEBP')
    )


@receiver(pre_save, sender=Story)
def optimize_story_cover_image(sender, instance, **kwargs):
    """
    Оптимизирует обложку истории перед сохранением.
    """
    if not should_optimize_image(instance, Story, field_name='cover_image_file'):
        return
    
    config = getattr(settings, 'IMAGE_OPTIMIZATION', {})
    logger.info(f"[ImageOptimization] Optimizing story cover image: {instance.cover_image_file.name}")
    
    optimize_image(
        instance.cover_image_file,
        max_width=config.get('MAX_WIDTH', 1920),
        max_height=config.get('MAX_HEIGHT', 1920),
        quality=config.get('QUALITY', 85),
        format=config.get('FORMAT', 'WEBP')
    )

