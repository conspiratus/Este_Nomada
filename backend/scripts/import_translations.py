"""
Скрипт для импорта переводов из JSON файлов в Django БД.
"""
import os
import sys
import django
import json

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from core.models import Translation

def import_translations_from_file(locale: str, file_path: str):
    """Импортирует переводы из JSON файла."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        for namespace, keys in data.items():
            if isinstance(keys, dict):
                for key, value in keys.items():
                    if isinstance(value, str):
                        Translation.objects.update_or_create(
                            locale=locale,
                            namespace=namespace,
                            key=key,
                            defaults={'value': value}
                        )
                        count += 1
        
        print(f'✓ Импортировано {count} переводов для локали {locale}')
        return count
    except Exception as e:
        print(f'✗ Ошибка при импорте {file_path}: {e}')
        return 0

if __name__ == '__main__':
    # Путь к файлам переводов в Next.js проекте
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    messages_dir = os.path.join(base_dir, 'messages')
    
    if not os.path.exists(messages_dir):
        print(f'Директория {messages_dir} не найдена')
        sys.exit(1)
    
    locales = ['ru', 'en', 'es']
    total = 0
    
    for locale in locales:
        file_path = os.path.join(messages_dir, f'{locale}.json')
        if os.path.exists(file_path):
            count = import_translations_from_file(locale, file_path)
            total += count
        else:
            print(f'⚠ Файл {file_path} не найден')
    
    print(f'\n✅ Всего импортировано {total} переводов')




