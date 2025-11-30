"""
Management команда для импорта цен из CSV/Excel файлов.
Использование:
    python manage.py import_prices --source carrefour --file prices.csv
    python manage.py import_prices --source alcampo --file prices.xlsx
"""
import csv
import os
from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone
from core.models import Ingredient, PriceSource
from decimal import Decimal, InvalidOperation


class Command(BaseCommand):
    help = 'Импорт цен ингредиентов из CSV или Excel файлов'

    def add_arguments(self, parser):
        parser.add_argument(
            '--source',
            type=str,
            required=True,
            help='Название источника цен (например: carrefour, alcampo, makro)'
        )
        parser.add_argument(
            '--file',
            type=str,
            required=True,
            help='Путь к файлу с ценами (CSV или Excel)'
        )
        parser.add_argument(
            '--name-column',
            type=str,
            default='name',
            help='Название колонки с названием продукта (по умолчанию: name)'
        )
        parser.add_argument(
            '--price-column',
            type=str,
            default='price',
            help='Название колонки с ценой (по умолчанию: price)'
        )
        parser.add_argument(
            '--quantity-column',
            type=str,
            default='quantity',
            help='Название колонки с количеством (по умолчанию: quantity)'
        )
        parser.add_argument(
            '--unit-column',
            type=str,
            default='unit',
            help='Название колонки с единицей измерения (по умолчанию: unit)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Показать что будет обновлено без сохранения в БД'
        )

    def handle(self, *args, **options):
        source_name = options['source']
        file_path = options['file']
        
        # Проверяем существование файла
        if not os.path.exists(file_path):
            raise CommandError(f'Файл не найден: {file_path}')
        
        # Получаем или создаем источник цен
        price_source, created = PriceSource.objects.get_or_create(
            name=source_name,
            defaults={
                'slug': source_name.lower().replace(' ', '-'),
                'active': True,
            }
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS(f'Создан новый источник цен: {price_source.name}'))
        
        # Определяем формат файла
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext == '.csv':
            self.import_from_csv(file_path, price_source, options)
        elif file_ext in ['.xlsx', '.xls']:
            self.import_from_excel(file_path, price_source, options)
        else:
            raise CommandError(f'Неподдерживаемый формат файла: {file_ext}. Используйте CSV или Excel.')
        
        # Обновляем время последней синхронизации
        if not options['dry_run']:
            price_source.last_sync = timezone.now()
            price_source.save()
            self.stdout.write(self.style.SUCCESS(f'Импорт завершен. Обновлено время синхронизации для {price_source.name}'))

    def import_from_csv(self, file_path, price_source, options):
        """Импорт цен из CSV файла."""
        updated_count = 0
        not_found_count = 0
        error_count = 0
        
        name_col = options['name_column']
        price_col = options['price_column']
        quantity_col = options['quantity_column']
        unit_col = options['unit_column']
        
        with open(file_path, 'r', encoding='utf-8') as f:
            # Пробуем определить разделитель
            sample = f.read(1024)
            f.seek(0)
            sniffer = csv.Sniffer()
            delimiter = sniffer.sniff(sample).delimiter
            
            reader = csv.DictReader(f, delimiter=delimiter)
            
            for row_num, row in enumerate(reader, start=2):
                try:
                    ingredient_name = row.get(name_col, '').strip()
                    if not ingredient_name:
                        continue
                    
                    # Ищем ингредиент по названию
                    ingredient = Ingredient.objects.filter(name__iexact=ingredient_name).first()
                    
                    if not ingredient:
                        self.stdout.write(
                            self.style.WARNING(f'Строка {row_num}: Ингредиент "{ingredient_name}" не найден')
                        )
                        not_found_count += 1
                        continue
                    
                    # Парсим цену
                    price_str = row.get(price_col, '').strip().replace(',', '.')
                    if not price_str:
                        continue
                    
                    try:
                        price = Decimal(price_str)
                    except (InvalidOperation, ValueError):
                        self.stdout.write(
                            self.style.ERROR(f'Строка {row_num}: Неверный формат цены: {price_str}')
                        )
                        error_count += 1
                        continue
                    
                    # Парсим количество (если указано)
                    quantity = None
                    if quantity_col in row and row[quantity_col]:
                        try:
                            quantity = Decimal(row[quantity_col].strip().replace(',', '.'))
                        except (InvalidOperation, ValueError):
                            pass
                    
                    # Парсим единицу измерения (если указана)
                    unit = None
                    if unit_col in row and row[unit_col]:
                        unit = row[unit_col].strip()
                    
                    # Обновляем ингредиент
                    if not options['dry_run']:
                        ingredient.price = price
                        if quantity:
                            ingredient.quantity = quantity
                        if unit and unit in dict(ingredient.UNIT_CHOICES):
                            ingredient.unit = unit
                        ingredient.price_source = price_source
                        ingredient.price_updated_at = timezone.now()
                        ingredient.save()
                    
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'Строка {row_num}: Обновлен {ingredient.name} - {price}€'
                        )
                    )
                    updated_count += 1
                    
                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'Строка {row_num}: Ошибка - {str(e)}')
                    )
                    error_count += 1
        
        # Выводим статистику
        self.stdout.write(self.style.SUCCESS(f'\nСтатистика импорта:'))
        self.stdout.write(f'  Обновлено: {updated_count}')
        self.stdout.write(f'  Не найдено: {not_found_count}')
        self.stdout.write(f'  Ошибок: {error_count}')

    def import_from_excel(self, file_path, price_source, options):
        """Импорт цен из Excel файла."""
        try:
            import openpyxl
        except ImportError:
            raise CommandError(
                'Для импорта Excel файлов требуется библиотека openpyxl. '
                'Установите её: pip install openpyxl'
            )
        
        updated_count = 0
        not_found_count = 0
        error_count = 0
        
        name_col = options['name_column']
        price_col = options['price_column']
        quantity_col = options['quantity_column']
        unit_col = options['unit_column']
        
        workbook = openpyxl.load_workbook(file_path)
        sheet = workbook.active
        
        # Находим заголовки
        headers = {}
        for col_idx, cell in enumerate(sheet[1], start=1):
            headers[cell.value] = col_idx
        
        if name_col not in headers or price_col not in headers:
            raise CommandError(
                f'Не найдены необходимые колонки. '
                f'Ожидаются: {name_col}, {price_col}. '
                f'Найдены: {list(headers.keys())}'
            )
        
        # Читаем данные
        for row_num, row in enumerate(sheet.iter_rows(min_row=2, values_only=False), start=2):
            try:
                ingredient_name = row[headers[name_col] - 1].value
                if not ingredient_name or not str(ingredient_name).strip():
                    continue
                
                ingredient_name = str(ingredient_name).strip()
                
                # Ищем ингредиент
                ingredient = Ingredient.objects.filter(name__iexact=ingredient_name).first()
                
                if not ingredient:
                    self.stdout.write(
                        self.style.WARNING(f'Строка {row_num}: Ингредиент "{ingredient_name}" не найден')
                    )
                    not_found_count += 1
                    continue
                
                # Парсим цену
                price_value = row[headers[price_col] - 1].value
                if not price_value:
                    continue
                
                try:
                    price = Decimal(str(price_value).replace(',', '.'))
                except (InvalidOperation, ValueError):
                    self.stdout.write(
                        self.style.ERROR(f'Строка {row_num}: Неверный формат цены: {price_value}')
                    )
                    error_count += 1
                    continue
                
                # Парсим количество (если указано)
                quantity = None
                if quantity_col in headers:
                    qty_value = row[headers[quantity_col] - 1].value
                    if qty_value:
                        try:
                            quantity = Decimal(str(qty_value).replace(',', '.'))
                        except (InvalidOperation, ValueError):
                            pass
                
                # Парсим единицу измерения (если указана)
                unit = None
                if unit_col in headers:
                    unit_value = row[headers[unit_col] - 1].value
                    if unit_value:
                        unit = str(unit_value).strip()
                
                # Обновляем ингредиент
                if not options['dry_run']:
                    ingredient.price = price
                    if quantity:
                        ingredient.quantity = quantity
                    if unit and unit in dict(ingredient.UNIT_CHOICES):
                        ingredient.unit = unit
                    ingredient.price_source = price_source
                    ingredient.price_updated_at = timezone.now()
                    ingredient.save()
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Строка {row_num}: Обновлен {ingredient.name} - {price}€'
                    )
                )
                updated_count += 1
                
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f'Строка {row_num}: Ошибка - {str(e)}')
                )
                error_count += 1
        
        # Выводим статистику
        self.stdout.write(self.style.SUCCESS(f'\nСтатистика импорта:'))
        self.stdout.write(f'  Обновлено: {updated_count}')
        self.stdout.write(f'  Не найдено: {not_found_count}')
        self.stdout.write(f'  Ошибок: {error_count}')

