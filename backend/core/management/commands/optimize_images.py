"""
Команда для оптимизации существующих изображений в базе данных.
"""
from django.core.management.base import BaseCommand
from django.core.files.storage import default_storage
from core.models import MenuItemImage, ContentSection
from core.utils import optimize_image
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Оптимизирует все существующие изображения в базе данных'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Показать что будет сделано без реальной обработки',
        )
        parser.add_argument(
            '--model',
            type=str,
            choices=['MenuItemImage', 'ContentSection', 'all'],
            default='all',
            help='Модель для обработки',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        model_choice = options['model']
        
        config = getattr(settings, 'IMAGE_OPTIMIZATION', {})
        
        if not config.get('ENABLED', True):
            self.stdout.write(self.style.WARNING('Image optimization is disabled in settings'))
            return
        
        self.stdout.write(self.style.SUCCESS('Starting image optimization...'))
        
        total_processed = 0
        total_optimized = 0
        
        # Обработка MenuItemImage
        if model_choice in ('MenuItemImage', 'all'):
            self.stdout.write('\nProcessing MenuItemImage...')
            menu_images = MenuItemImage.objects.filter(image__isnull=False).exclude(image='')
            
            for item in menu_images:
                if not item.image or not item.image.name:
                    continue
                
                if not default_storage.exists(item.image.name):
                    self.stdout.write(self.style.WARNING(f'  Image not found: {item.image.name}'))
                    continue
                
                total_processed += 1
                
                if dry_run:
                    self.stdout.write(f'  Would optimize: {item.image.name}')
                    continue
                
                self.stdout.write(f'  Optimizing: {item.image.name}')
                if optimize_image(
                    item.image,
                    max_width=800,  # Уменьшено для карточек меню
                    max_height=800,
                    quality=config.get('QUALITY', 85),
                    format=config.get('FORMAT', 'WEBP')
                ):
                    total_optimized += 1
                    item.save()  # Сохраняем изменения
        
        # Обработка ContentSection
        if model_choice in ('ContentSection', 'all'):
            self.stdout.write('\nProcessing ContentSection...')
            sections = ContentSection.objects.filter(image__isnull=False).exclude(image='')
            
            for section in sections:
                if not section.image or not section.image.name:
                    continue
                
                if not default_storage.exists(section.image.name):
                    self.stdout.write(self.style.WARNING(f'  Image not found: {section.image.name}'))
                    continue
                
                total_processed += 1
                
                if dry_run:
                    self.stdout.write(f'  Would optimize: {section.image.name}')
                    continue
                
                self.stdout.write(f'  Optimizing: {section.image.name}')
                if optimize_image(
                    section.image,
                    max_width=config.get('MAX_WIDTH', 1920),
                    max_height=config.get('MAX_HEIGHT', 1920),
                    quality=config.get('QUALITY', 85),
                    format=config.get('FORMAT', 'WEBP')
                ):
                    total_optimized += 1
                    section.save()  # Сохраняем изменения
        
        self.stdout.write(self.style.SUCCESS(
            f'\nCompleted! Processed: {total_processed}, Optimized: {total_optimized}'
        ))

