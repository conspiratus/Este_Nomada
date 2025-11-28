#!/usr/bin/env python3
"""
Скрипт для загрузки новых переводов из JSON файлов в базу данных.
Использование: python manage.py shell < scripts/load_new_translations.py
Или: python scripts/load_new_translations.py (если запускается из корня проекта)
"""
import os
import sys
import json
import django

# Настройка Django
if __name__ == '__main__':
    # Определяем путь к settings
    script_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(script_dir)
    project_root = os.path.dirname(backend_dir)
    
    sys.path.insert(0, backend_dir)
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
    django.setup()

from core.models import Translation

def load_translations_from_json():
    """Загружает все переводы из JSON файлов в БД."""
    # Путь к JSON файлам
    script_dir = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.dirname(script_dir)
    project_root = os.path.dirname(backend_dir)
    messages_dir = os.path.join(project_root, 'messages')
    
    print(f'📁 Ищу JSON файлы в: {messages_dir}')
    
    if not os.path.exists(messages_dir):
        print(f'❌ Директория не найдена: {messages_dir}')
        return
    
    # Локали для обработки
    locales = ['ru', 'es', 'en']
    
    total_created = 0
    total_updated = 0
    
    for locale in locales:
        json_file = os.path.join(messages_dir, f'{locale}.json')
        
        if not os.path.exists(json_file):
            print(f'⚠️  JSON файл не найден: {json_file}')
            continue
        
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                translations_data = json.load(f)
            
            print(f'\n🌍 Загружаю переводы для локали: {locale}')
            
            # Рекурсивно обходим JSON структуру
            def process_dict(data, namespace=''):
                """Рекурсивно обрабатывает вложенные словари."""
                created = 0
                updated = 0
                for key, value in data.items():
                    if isinstance(value, dict):
                        # Если значение - словарь, это namespace
                        current_namespace = f"{namespace}.{key}" if namespace else key
                        # Рекурсивно обрабатываем вложенную структуру
                        sub_created, sub_updated = process_dict(value, current_namespace)
                        created += sub_created
                        updated += sub_updated
                    elif isinstance(value, str):
                        # Строковое значение - создаем или обновляем перевод
                        current_namespace = namespace if namespace else 'common'
                        trans, was_created = Translation.objects.get_or_create(
                            locale=locale,
                            namespace=current_namespace,
                            key=key,
                            defaults={'value': value}
                        )
                        if was_created:
                            created += 1
                        elif trans.value != value:
                            # Обновляем значение, если оно изменилось
                            trans.value = value
                            trans.save()
                            updated += 1
                return created, updated
            
            # Обрабатываем все переводы
            created, updated = process_dict(translations_data)
            total_created += created
            total_updated += updated
            
            print(f'  ✅ Создано: {created}, Обновлено: {updated}')
            
        except Exception as e:
            print(f'❌ Ошибка при загрузке переводов для {locale}: {str(e)}')
            import traceback
            traceback.print_exc()
            continue
    
    print(f'\n📊 Итого:')
    print(f'  ✅ Создано переводов: {total_created}')
    print(f'  🔄 Обновлено переводов: {total_updated}')
    print(f'\n✨ Готово!')

if __name__ == '__main__':
    load_translations_from_json()

