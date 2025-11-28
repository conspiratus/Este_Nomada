# Generated manually on 2025-11-28

from django.db import migrations
import json
import os


def load_translations_from_json(apps, schema_editor):
    """Загружает все переводы из JSON файлов в БД."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Путь к JSON файлам - используем несколько вариантов для надежности
    # Вариант 1: от миграции вверх до корня проекта
    migration_file = __file__
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(migration_file))))
    messages_dir = os.path.join(base_dir, 'messages')
    
    # Если не нашли, пробуем вариант 2: от backend вверх
    if not os.path.exists(messages_dir):
        backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(migration_file)))
        base_dir = os.path.dirname(backend_dir)
        messages_dir = os.path.join(base_dir, 'messages')
    
    # Если все еще не нашли, пробуем вариант 3: абсолютный путь от текущей директории
    if not os.path.exists(messages_dir):
        import django
        from django.conf import settings
        try:
            # Пробуем получить BASE_DIR из settings
            base_dir = getattr(settings, 'BASE_DIR', None)
            if base_dir:
                # Идем на уровень выше от backend
                base_dir = os.path.dirname(os.path.dirname(base_dir))
                messages_dir = os.path.join(base_dir, 'messages')
        except:
            pass
    
    print(f'[Migration] Looking for messages in: {messages_dir}')
    
    # Локали для обработки
    locales = ['ru', 'es', 'en']
    
    for locale in locales:
        json_file = os.path.join(messages_dir, f'{locale}.json')
        
        if not os.path.exists(json_file):
            print(f'[Migration] JSON file not found: {json_file}')
            continue
        
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                translations_data = json.load(f)
            
            print(f'[Migration] Loading translations for locale: {locale}')
            
            # Рекурсивно обходим JSON структуру
            def process_dict(data, namespace=''):
                """Рекурсивно обрабатывает вложенные словари."""
                count = 0
                for key, value in data.items():
                    if isinstance(value, dict):
                        # Если значение - словарь, это namespace
                        current_namespace = f"{namespace}.{key}" if namespace else key
                        # Рекурсивно обрабатываем вложенную структуру
                        count += process_dict(value, current_namespace)
                    elif isinstance(value, str):
                        # Строковое значение - создаем перевод
                        current_namespace = namespace if namespace else 'common'
                        trans, created = Translation.objects.using(db_alias).get_or_create(
                            locale=locale,
                            namespace=current_namespace,
                            key=key,
                            defaults={'value': value}
                        )
                        if created:
                            count += 1
                return count
            
            # Обрабатываем все переводы
            total_created = process_dict(translations_data)
            print(f'[Migration] Created {total_created} translations for locale: {locale}')
            
            # Обрабатываем все переводы
            process_dict(translations_data)
            
            print(f'[Migration] Successfully loaded translations for locale: {locale}')
            
        except Exception as e:
            print(f'[Migration] Error loading translations for {locale}: {str(e)}')
            # Продолжаем обработку других локалей даже при ошибке
            continue


def reverse_migration(apps, schema_editor):
    """Откат миграции - можно оставить пустым или удалить созданные переводы."""
    # Оставляем пустым, так как это миграция данных
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0030_add_is_pickup_to_order'),
    ]

    operations = [
        migrations.RunPython(load_translations_from_json, reverse_migration),
    ]

