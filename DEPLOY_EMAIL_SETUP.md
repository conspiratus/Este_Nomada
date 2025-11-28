# 🚀 Быстрая настройка Email на Production

## Автоматическая настройка (1 команда)

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one "cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c && chmod +x scripts/setup_email_on_server.sh && ./scripts/setup_email_on_server.sh"
```

Или подключитесь к серверу и запустите:

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c
chmod +x scripts/setup_email_on_server.sh
./scripts/setup_email_on_server.sh
```

Скрипт попросит:
1. Email для отправки писем (например, `info@estenomada.es`)
2. Пароль от этого email
3. Email для тестового письма (опционально)

## Что делает скрипт

✅ Создает резервную копию `.env`  
✅ Добавляет настройки SMTP one.com в `.env`  
✅ Тестирует отправку письма  
✅ Показывает статус настройки  

## Настройки SMTP one.com

```
SMTP server: send.one.com
SMTP port: 465 (SSL)
EMAIL_USE_SSL: True
EMAIL_USE_TLS: False
```

## Проверка после настройки

### 1. Проверьте настройки в .env

```bash
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c/backend
cat .env | grep EMAIL
```

Должно быть:
```
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=send.one.com
EMAIL_PORT=465
EMAIL_USE_SSL=True
EMAIL_USE_TLS=False
EMAIL_HOST_USER=your-email@estenomada.es
DEFAULT_FROM_EMAIL=your-email@estenomada.es
```

### 2. Тест через Django shell

```bash
cd backend
source venv/bin/activate
python manage.py shell
```

```python
from django.core.mail import send_mail
from django.conf import settings

send_mail(
    'Test Email',
    'This is a test email from Este Nómada',
    settings.DEFAULT_FROM_EMAIL,
    ['your-test-email@example.com'],
    fail_silently=False,
)
```

### 3. Проверьте логи

```bash
tail -f backend/logs/django.log
```

## Если что-то не работает

### Проблема: Письма не отправляются

1. **Проверьте пароль:**
   ```bash
   # Убедитесь, что пароль правильный в .env
   cat backend/.env | grep EMAIL_HOST_PASSWORD
   ```

2. **Проверьте подключение к SMTP:**
   ```bash
   telnet send.one.com 465
   # Или
   openssl s_client -connect send.one.com:465
   ```

3. **Проверьте логи Django:**
   ```bash
   tail -50 backend/logs/django.log | grep -i email
   ```

### Проблема: Письма попадают в спам

- Используйте email с доменом `@estenomada.es`
- Настройте SPF и DKIM записи в DNS (через панель one.com)
- Убедитесь, что `DEFAULT_FROM_EMAIL` совпадает с `EMAIL_HOST_USER`

### Проблема: Ошибка SSL/TLS

Убедитесь, что в `.env`:
```
EMAIL_USE_SSL=True
EMAIL_USE_TLS=False
```

Порт 465 использует SSL, а не TLS!

## Ручная настройка (если скрипт не работает)

1. Отредактируйте `backend/.env`:
   ```bash
   nano backend/.env
   ```

2. Добавьте:
   ```env
   EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
   EMAIL_HOST=send.one.com
   EMAIL_PORT=465
   EMAIL_USE_TLS=False
   EMAIL_USE_SSL=True
   EMAIL_HOST_USER=info@estenomada.es
   EMAIL_HOST_PASSWORD=your-password
   DEFAULT_FROM_EMAIL=info@estenomada.es
   SERVER_EMAIL=info@estenomada.es
   ```

3. Перезапустите Django:
   ```bash
   sudo systemctl restart estenomada-backend
   # Или если используете другой способ запуска
   ```

## Использование в коде

После настройки email будет работать автоматически для:
- ✅ Подтверждения регистрации (`CustomerViewSet.register`)
- ✅ Восстановления пароля
- ✅ Уведомлений о заказах
- ✅ Любых других писем через `send_mail()`

Пример:
```python
from django.core.mail import send_mail

send_mail(
    subject='Подтверждение email',
    message='Перейдите по ссылке для подтверждения...',
    from_email=None,  # Использует DEFAULT_FROM_EMAIL
    recipient_list=['user@example.com'],
)
```

## Безопасность

⚠️ **Важно:**
- Файл `.env` содержит пароли - не коммитьте его в git!
- Используйте сильный пароль для email
- Регулярно меняйте пароль
- Резервные копии `.env.backup.*` также содержат пароли - храните их безопасно

