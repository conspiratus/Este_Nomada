#!/usr/bin/env python3
"""
Скрипт для проверки permissions для verify_email endpoint.
Запускать на сервере в директории /var/www/estenomada/backend
"""
import os
import sys
import django

# Настройка Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from api.views import CustomerViewSet
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.test import APIRequestFactory
from django.contrib.auth import get_user_model

User = get_user_model()

print("=" * 60)
print("Проверка permissions для verify_email endpoint")
print("=" * 60)

# Создаем ViewSet
viewset = CustomerViewSet()

# Проверяем get_permissions для verify_email
viewset.action = 'verify_email'
perms = viewset.get_permissions()

print(f"\n1. Действие: verify_email")
print(f"   Permissions: {[type(p).__name__ for p in perms]}")
print(f"   Первый permission - AllowAny: {isinstance(perms[0], AllowAny) if perms else False}")

# Проверяем для других действий
for action in ['register', 'login', 'list', 'retrieve']:
    viewset.action = action
    perms = viewset.get_permissions()
    expected = AllowAny if action in ['register', 'login'] else IsAuthenticated
    is_correct = isinstance(perms[0], expected) if perms else False
    print(f"\n2. Действие: {action}")
    print(f"   Permissions: {[type(p).__name__ for p in perms]}")
    print(f"   Ожидается: {expected.__name__}, Получено: {type(perms[0]).__name__ if perms else 'None'}")
    print(f"   Правильно: {is_correct}")

# Проверяем сам метод verify_email
print("\n" + "=" * 60)
print("Проверка метода verify_email")
print("=" * 60)

factory = APIRequestFactory()
request = factory.get('/api/customers/verify-email/?token=test')
viewset.request = request
viewset.action = 'verify_email'

# Получаем permissions для этого запроса
perms = viewset.get_permissions()
print(f"\nPermissions для GET /api/customers/verify-email/:")
print(f"  {[type(p).__name__ for p in perms]}")

# Проверяем, что AllowAny разрешает доступ без авторизации
from rest_framework.permissions import AllowAny as AllowAnyClass
allow_any = AllowAnyClass()
has_permission = allow_any.has_permission(request, viewset)
print(f"\nAllowAny.has_permission для неавторизованного запроса: {has_permission}")

print("\n" + "=" * 60)
print("✅ Проверка завершена")
print("=" * 60)

