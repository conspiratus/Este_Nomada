"""
Скрипт для миграции данных из старой БД в Django.
Запускать после создания миграций Django.
"""
import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

import mysql.connector
from django.conf import settings
from core.models import Story, MenuItem, Settings

def migrate_data():
    """Мигрировать данные из старой БД."""
    # Подключение к старой БД
    old_db = mysql.connector.connect(
        host=settings.DATABASES['default']['HOST'],
        user=settings.DATABASES['default']['USER'],
        password=settings.DATABASES['default']['PASSWORD'],
        database=settings.DATABASES['default']['NAME']
    )
    
    cursor = old_db.cursor(dictionary=True)
    
    # Миграция историй
    print("Миграция историй...")
    cursor.execute("SELECT * FROM stories")
    stories = cursor.fetchall()
    
    for story_data in stories:
        if not Story.objects.filter(slug=story_data['slug']).exists():
            Story.objects.create(
                title=story_data['title'],
                slug=story_data['slug'],
                date=story_data['date'],
                excerpt=story_data.get('excerpt'),
                content=story_data['content'],
                cover_image=story_data.get('cover_image'),
                source=story_data.get('source', 'manual'),
                published=bool(story_data.get('published', True))
            )
            print(f"  ✓ Мигрирована история: {story_data['title']}")
    
    # Миграция меню
    print("Миграция меню...")
    cursor.execute("SELECT * FROM menu_items")
    menu_items = cursor.fetchall()
    
    for item_data in menu_items:
        if not MenuItem.objects.filter(id=item_data['id']).exists():
            MenuItem.objects.create(
                id=item_data['id'],
                name=item_data['name'],
                description=item_data.get('description'),
                category=item_data['category'],
                price=float(item_data['price']) if item_data.get('price') else None,
                image=item_data.get('image'),
                order=item_data.get('order', 0),
                active=bool(item_data.get('active', True))
            )
            print(f"  ✓ Мигрировано блюдо: {item_data['name']}")
    
    # Миграция настроек
    print("Миграция настроек...")
    cursor.execute("SELECT * FROM settings LIMIT 1")
    settings_data = cursor.fetchone()
    
    if settings_data:
        settings_obj = Settings.get_settings()
        settings_obj.site_name = settings_data.get('site_name', 'Este Nómada')
        settings_obj.site_description = settings_data.get('site_description')
        settings_obj.contact_email = settings_data.get('contact_email')
        settings_obj.telegram_channel = settings_data.get('telegram_channel')
        settings_obj.bot_token = settings_data.get('bot_token')
        settings_obj.channel_id = settings_data.get('channel_id')
        settings_obj.auto_sync = bool(settings_data.get('auto_sync', False))
        settings_obj.save()
        print("  ✓ Настройки мигрированы")
    
    cursor.close()
    old_db.close()
    print("\nМиграция завершена!")

if __name__ == '__main__':
    migrate_data()



