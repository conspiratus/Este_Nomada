"""
Скрипт для создания администратора.
"""
import os
import sys
import django

# Настройка Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.core.management import call_command

User = get_user_model()

def create_admin(username='admin', password='admin123', email='admin@estenomada.es'):
    """Создать администратора."""
    if User.objects.filter(username=username).exists():
        print(f'Пользователь {username} уже существует')
        return
    
    User.objects.create_superuser(
        username=username,
        email=email,
        password=password
    )
    print(f'Администратор {username} создан успешно')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Создать администратора')
    parser.add_argument('--username', default='admin', help='Имя пользователя')
    parser.add_argument('--password', default='admin123', help='Пароль')
    parser.add_argument('--email', default='admin@estenomada.es', help='Email')
    
    args = parser.parse_args()
    create_admin(args.username, args.password, args.email)




