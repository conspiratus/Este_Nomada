"""
Инициализация БД: создание миграций и начальных данных.
"""
import os
import sys
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from django.core.management import call_command
from core.models import Settings, MenuItem

def init_db():
    """Инициализировать БД."""
    print("Создание миграций...")
    call_command('makemigrations')
    
    print("Применение миграций...")
    call_command('migrate')
    
    print("Создание начальных данных...")
    
    # Настройки
    if not Settings.objects.exists():
        Settings.objects.create(
            site_name='Este Nómada',
            site_description='Кухня Востока, рожденная в пути',
            contact_email='info@estenomada.es',
            telegram_channel='https://t.me/este_nomada'
        )
        print("  ✓ Настройки созданы")
    
    # Начальное меню
    initial_menu = [
        {'name': 'Плов', 'description': 'Традиционный узбекский плов с бараниной, морковью и специями', 'category': 'Плов', 'order': 1},
        {'name': 'Мастава', 'description': 'Густой суп с мясом, овощами и рисом, приправленный специями', 'category': 'Мастава', 'order': 2},
        {'name': 'Долма', 'description': 'Виноградные листья, фаршированные мясом и рисом', 'category': 'Долма', 'order': 3},
        {'name': 'Лагман', 'description': 'Домашняя лапша с мясом и овощами в ароматном бульоне', 'category': 'Супы', 'order': 4},
        {'name': 'Самса', 'description': 'Пирожки с мясом и луком, запечённые в тандыре', 'category': 'Холодные закуски', 'order': 5},
        {'name': 'Манты', 'description': 'Парные пельмени с мясом и луком, подаются со сметаной', 'category': 'Холодные закуски', 'order': 6},
        {'name': 'Шашлык', 'description': 'Мясо на углях, маринованное в специях', 'category': 'Особые блюда', 'order': 7},
        {'name': 'Чай', 'description': 'Традиционный восточный чай с травами', 'category': 'Напитки', 'order': 8},
    ]
    
    for item_data in initial_menu:
        if not MenuItem.objects.filter(name=item_data['name']).exists():
            MenuItem.objects.create(**item_data)
            print(f"  ✓ Создано блюдо: {item_data['name']}")
    
    print("\nИнициализация завершена!")

if __name__ == '__main__':
    init_db()




