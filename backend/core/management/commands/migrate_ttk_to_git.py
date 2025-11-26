"""
Management команда для миграции ТТК файлов из FileField в Git репозиторий.
"""
from django.core.management.base import BaseCommand
from django.conf import settings
from core.models import DishTTK
from core.git_utils import TTKGitRepository
import os


class Command(BaseCommand):
    help = 'Мигрирует ТТК файлы из FileField в Git репозиторий'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Показать, что будет сделано, без реальной миграции',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        if not settings.TTK_USE_GIT:
            self.stdout.write(self.style.ERROR('TTK_USE_GIT отключен в настройках. Включите его для миграции.'))
            return
        
        repo = TTKGitRepository(
            settings.TTK_GIT_REPO_PATH,
            settings.TTK_GIT_USER_NAME,
            settings.TTK_GIT_USER_EMAIL
        )
        
        self.stdout.write(f'Git репозиторий: {settings.TTK_GIT_REPO_PATH}')
        
        # Получаем все ТТК с файлами
        ttks = DishTTK.objects.filter(ttk_file__isnull=False).select_related('menu_item')
        
        self.stdout.write(f'Найдено ТТК с файлами: {ttks.count()}')
        
        migrated = 0
        skipped = 0
        errors = 0
        
        for ttk in ttks:
            dish = ttk.menu_item
            self.stdout.write(f'\nОбработка: {dish.name} (ID: {dish.id})')
            
            # Проверяем, существует ли файл
            if not ttk.ttk_file or not os.path.exists(ttk.ttk_file.path):
                self.stdout.write(self.style.WARNING(f'  Файл не найден: {ttk.ttk_file.path if ttk.ttk_file else "N/A"}'))
                skipped += 1
                continue
            
            # Проверяем, есть ли уже файл в Git
            if repo.file_exists(dish.id, dish.name):
                self.stdout.write(self.style.WARNING(f'  Файл уже существует в Git, пропускаем'))
                skipped += 1
                continue
            
            # Читаем содержимое файла
            try:
                with open(ttk.ttk_file.path, 'r', encoding='utf-8') as f:
                    content = f.read()
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'  Ошибка чтения файла: {e}'))
                errors += 1
                continue
            
            if dry_run:
                self.stdout.write(self.style.SUCCESS(f'  [DRY RUN] Будет создан файл в Git'))
                self.stdout.write(f'    Размер: {len(content)} символов')
            else:
                # Записываем в Git
                commit_message = f"Миграция из FileField: {dish.name}"
                if ttk.version:
                    commit_message += f" (версия {ttk.version})"
                
                success = repo.write_file(
                    dish.id,
                    dish.name,
                    content,
                    commit_message
                )
                
                if success:
                    self.stdout.write(self.style.SUCCESS(f'  ✅ Успешно мигрировано в Git'))
                    migrated += 1
                else:
                    self.stdout.write(self.style.ERROR(f'  ❌ Ошибка при записи в Git'))
                    errors += 1
        
        self.stdout.write('\n' + '='*50)
        self.stdout.write(f'Итого:')
        if not dry_run:
            self.stdout.write(self.style.SUCCESS(f'  Мигрировано: {migrated}'))
        else:
            self.stdout.write(f'  Будет мигрировано: {migrated}')
        self.stdout.write(f'  Пропущено: {skipped}')
        self.stdout.write(f'  Ошибок: {errors}')
        
        if dry_run:
            self.stdout.write('\n' + self.style.WARNING('Это был dry-run. Запустите без --dry-run для реальной миграции.'))

