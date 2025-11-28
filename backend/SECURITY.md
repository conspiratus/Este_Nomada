# Безопасность данных

## Шифрование персональных данных

Все персональные данные клиентов хранятся в зашифрованном виде в базе данных:

### Зашифрованные поля:

**Модель `Customer`:**
- ✅ `email` - зашифровано
- ✅ `phone` - зашифровано
- ✅ `name` - зашифровано
- ✅ `postal_code` - зашифровано
- ✅ `address` - зашифровано

**Модель `Order`:**
- ✅ `email` - зашифровано
- ✅ `phone` - зашифровано
- ✅ `name` - зашифровано
- ✅ `postal_code` - зашифровано
- ✅ `address` - зашифровано

### Генерация ключа шифрования

Для production необходимо сгенерировать уникальный ключ шифрования:

```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Скопируйте полученный ключ и добавьте в `.env.production`:

```
ENCRYPTION_KEY=ваш-сгенерированный-ключ-здесь
```

**⚠️ ВАЖНО:**
- Ключ должен быть уникальным для каждого окружения
- НЕ коммитьте ключ в Git
- Сохраните ключ в безопасном месте (если потеряете, данные не расшифруются)
- Используйте один и тот же ключ для всех серверов одного окружения

### Как работает шифрование

1. При сохранении данных в БД - данные автоматически шифруются через `EncryptedField`
2. При чтении из БД - данные автоматически расшифровываются
3. В базе данных хранятся только зашифрованные значения (начинаются с `gAAAAAB`)
4. Шифрование использует алгоритм Fernet (симметричное шифрование)

## HTTPS настройки

В production (`DEBUG=False`) автоматически активируются:

- ✅ `SECURE_SSL_REDIRECT` - принудительное перенаправление HTTP → HTTPS
- ✅ `SESSION_COOKIE_SECURE` - куки сессии только через HTTPS
- ✅ `CSRF_COOKIE_SECURE` - CSRF токены только через HTTPS
- ✅ `SECURE_HSTS_SECONDS` - HTTP Strict Transport Security (1 год)
- ✅ `SECURE_PROXY_SSL_HEADER` - поддержка работы за Nginx reverse proxy

## Проверка безопасности

### Проверить, что ключ установлен:

```bash
cd /var/www/estenomada/backend
source venv/bin/activate
python manage.py shell
>>> from django.conf import settings
>>> print(settings.ENCRYPTION_KEY is not None)
True
```

### Проверить, что данные зашифрованы в БД:

```sql
-- В MySQL
SELECT name, email, phone FROM orders LIMIT 1;
-- Значения должны начинаться с 'gAAAAAB' (зашифрованные)
```

### Проверить, что данные расшифровываются в Django:

```python
from core.models import Order
order = Order.objects.first()
print(order.name)  # Должно показать расшифрованное имя
print(order.email)  # Должно показать расшифрованный email
```

