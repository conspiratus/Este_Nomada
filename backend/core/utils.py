"""
Утилиты для обработки изображений.
"""
import os
import logging
from io import BytesIO
from PIL import Image
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage

logger = logging.getLogger(__name__)


def optimize_image(image_field, max_width=1920, max_height=1920, quality=85, format='WEBP'):
    """
    Оптимизирует изображение: сжимает, изменяет размер и конвертирует в WebP.
    
    Args:
        image_field: Django ImageField
        max_width: Максимальная ширина (по умолчанию 1920px)
        max_height: Максимальная высота (по умолчанию 1920px)
        quality: Качество сжатия WebP (0-100, по умолчанию 85)
        format: Формат выходного файла ('WEBP', 'JPEG', 'PNG')
    
    Returns:
        bool: True если изображение было обработано, False если обработка не требуется
    """
    if not image_field or not image_field.name:
        return False
    
    try:
        # Открываем изображение
        img = Image.open(image_field)
        
        # Конвертируем в RGB если нужно (для JPEG/WebP)
        if format in ('WEBP', 'JPEG') and img.mode in ('RGBA', 'LA', 'P'):
            # Создаем белый фон для прозрачных изображений
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background
        elif img.mode not in ('RGB', 'L'):
            img = img.convert('RGB')
        
        # Получаем текущие размеры
        original_width, original_height = img.size
        
        # Проверяем, нужно ли изменять размер
        needs_resize = original_width > max_width or original_height > max_height
        
        if needs_resize:
            # Вычисляем новые размеры с сохранением пропорций
            ratio = min(max_width / original_width, max_height / original_height)
            new_width = int(original_width * ratio)
            new_height = int(original_height * ratio)
            
            # Изменяем размер с использованием высококачественного алгоритма
            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Сохраняем в буфер
        output = BytesIO()
        
        # Выбираем формат и параметры сохранения
        if format == 'WEBP':
            img.save(output, format='WEBP', quality=quality, method=6)  # method=6 для лучшего сжатия
            ext = '.webp'
        elif format == 'JPEG':
            img.save(output, format='JPEG', quality=quality, optimize=True)
            ext = '.jpg'
        else:
            img.save(output, format=format, optimize=True)
            ext = f'.{format.lower()}'
        
        output.seek(0)
        
        # Получаем имя файла без расширения
        file_name = os.path.splitext(os.path.basename(image_field.name))[0]
        # Сохраняем путь директории
        dir_path = os.path.dirname(image_field.name) if os.path.dirname(image_field.name) else ''
        new_file_name = f"{file_name}{ext}"
        if dir_path:
            new_file_name = f"{dir_path}/{new_file_name}"
        
        # Сохраняем старое имя для возможного удаления
        old_name = image_field.name if image_field.name else None
        
        # Получаем размер до оптимизации
        old_size = None
        if old_name and default_storage.exists(old_name):
            try:
                old_size = default_storage.size(old_name)
            except Exception:
                pass
        
        # Сохраняем новое изображение
        image_field.save(
            new_file_name,
            ContentFile(output.read()),
            save=False
        )
        
        # Получаем размер после оптимизации
        new_size = None
        if image_field.name and default_storage.exists(image_field.name):
            try:
                new_size = default_storage.size(image_field.name)
            except Exception:
                pass
        
        # Логируем результаты
        if old_size and new_size:
            reduction = ((old_size - new_size) / old_size) * 100
            logger.info(
                f"[ImageOptimization] Image optimized: {old_name} -> {image_field.name} "
                f"({old_size} bytes -> {new_size} bytes, {reduction:.1f}% reduction)"
            )
        else:
            logger.info(f"[ImageOptimization] Image optimized: {old_name} -> {image_field.name}")
        
        # Удаляем старое изображение если формат изменился
        if old_name and old_name != image_field.name and default_storage.exists(old_name):
            try:
                default_storage.delete(old_name)
                logger.debug(f"[ImageOptimization] Deleted old image: {old_name}")
            except Exception as e:
                logger.warning(f"[ImageOptimization] Error deleting old image {old_name}: {e}")
        
        return True
        
    except Exception as e:
        logger.error(f"[ImageOptimization] Error optimizing image {image_field.name if image_field else 'unknown'}: {e}", exc_info=True)
        return False


def get_image_info(image_field):
    """
    Получает информацию об изображении (размеры, формат, размер файла).
    
    Args:
        image_field: Django ImageField
    
    Returns:
        dict: Информация об изображении или None
    """
    if not image_field or not image_field.name:
        return None
    
    try:
        img = Image.open(image_field)
        file_size = None
        if image_field.file and hasattr(image_field.file, 'size'):
            file_size = image_field.file.size
        elif image_field.name and default_storage.exists(image_field.name):
            file_size = default_storage.size(image_field.name)
        
        return {
            'width': img.width,
            'height': img.height,
            'format': img.format,
            'mode': img.mode,
            'file_size': file_size,
        }
    except Exception as e:
        logger.error(f"[ImageOptimization] Error getting image info: {e}", exc_info=True)
        return None

