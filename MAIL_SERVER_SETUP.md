# Настройка почтового сервера на one.com

## Варианты отправки писем

### Вариант 1: Использование SMTP one.com (РЕКОМЕНДУЕТСЯ)

One.com предоставляет SMTP сервер для отправки писем. Это самый простой и надежный способ.

#### Настройка в Django

**Данные SMTP one.com:**
- SMTP server: `send.one.com`
- SMTP port: `465` (SSL)
- IMAP server: `imap.one.com` (порт 993)
- POP3 server: `pop.one.com` (порт 995)

**Автоматическая настройка (рекомендуется):**

Запустите скрипт на сервере:
```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c
chmod +x scripts/setup_email_on_server.sh
./scripts/setup_email_on_server.sh
```

Скрипт автоматически:
- Настроит .env файл с правильными параметрами
- Попросит ввести email и пароль
- Отправит тестовое письмо

**Ручная настройка:**

Добавьте в `backend/.env`:

```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=send.one.com
EMAIL_PORT=465
EMAIL_USE_TLS=False
EMAIL_USE_SSL=True
EMAIL_HOST_USER=your-email@estenomada.es
EMAIL_HOST_PASSWORD=your-email-password
DEFAULT_FROM_EMAIL=your-email@estenomada.es
SERVER_EMAIL=your-email@estenomada.es
```

⚠️ **Важно:** Порт 465 использует SSL, а не TLS, поэтому `EMAIL_USE_SSL=True` и `EMAIL_USE_TLS=False`

### Вариант 2: Установка локального почтового сервера (Postfix)

Если нужно использовать локальный sendmail/postfix:

#### Шаг 1: Подключитесь к серверу

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one
```

#### Шаг 2: Запустите скрипт установки

```bash
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c
chmod +x scripts/install_mail_server.sh
./scripts/install_mail_server.sh
```

Или установите вручную:

```bash
# Для Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y postfix mailutils

# Настройка
sudo postconf -e "myhostname = estenomada.es"
sudo postconf -e "mydomain = estenomada.es"
sudo postconf -e "inet_interfaces = loopback-only"

# Запуск
sudo systemctl enable postfix
sudo systemctl restart postfix
```

#### Шаг 3: Настройка Django для локального sendmail

Добавьте в `backend/.env`:

```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=localhost
EMAIL_PORT=25
EMAIL_USE_TLS=False
DEFAULT_FROM_EMAIL=noreply@estenomada.es
```

### Вариант 3: Использование внешнего SMTP (Gmail, SendGrid и т.д.)

#### Gmail (для тестирования)

```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password  # НЕ обычный пароль, а App Password!
DEFAULT_FROM_EMAIL=your-email@gmail.com
```

**Как получить App Password для Gmail:**
1. Включите 2FA в Google аккаунте
2. Перейдите: https://myaccount.google.com/apppasswords
3. Создайте App Password для "Mail"
4. Используйте этот пароль в настройках

#### SendGrid (для production)

```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=apikey
EMAIL_HOST_PASSWORD=your-sendgrid-api-key
DEFAULT_FROM_EMAIL=noreply@estenomada.es
```

## Проверка работы

### Тест через Django shell

```bash
cd backend
source venv/bin/activate
python manage.py shell
```

```python
from django.core.mail import send_mail

send_mail(
    'Test Subject',
    'Test message from Este Nómada',
    'noreply@estenomada.es',
    ['your-email@example.com'],
    fail_silently=False,
)
```

### Тест через командную строку

```bash
# Если установлен postfix
echo "Test message" | mail -s "Test" your-email@example.com
```

## Настройка в Django settings.py

Убедитесь, что в `backend/este_nomada/settings.py` есть:

```python
# Email settings
EMAIL_BACKEND = env('EMAIL_BACKEND', default='django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST = env('EMAIL_HOST', default='localhost')
EMAIL_PORT = env.int('EMAIL_PORT', default=25)
EMAIL_USE_TLS = env.bool('EMAIL_USE_TLS', default=False)
EMAIL_USE_SSL = env.bool('EMAIL_USE_SSL', default=False)
EMAIL_HOST_USER = env('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = env('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = env('DEFAULT_FROM_EMAIL', default='noreply@estenomada.es')
```

## Рекомендации

1. **Для production:** Используйте SMTP one.com или внешний сервис (SendGrid, Mailgun)
2. **Для тестирования:** Можно использовать Gmail с App Password
3. **Локальный sendmail:** Подходит только если one.com разрешает отправку писем через локальный сервер

## Устранение проблем

### Письма не отправляются

1. Проверьте логи Django:
   ```bash
   tail -f backend/logs/django.log
   ```

2. Проверьте логи postfix (если используется):
   ```bash
   sudo journalctl -u postfix -f
   ```

3. Проверьте настройки в `.env`:
   ```bash
   cat backend/.env | grep EMAIL
   ```

4. Проверьте подключение к SMTP:
   ```bash
   telnet smtp.one.com 587
   ```

### Письма попадают в спам

- Используйте правильный `DEFAULT_FROM_EMAIL` (домен должен совпадать)
- Настройте SPF и DKIM записи в DNS (через панель one.com)
- Используйте надежный SMTP сервер (one.com, SendGrid)

## Безопасность

⚠️ **Важно:**
- Никогда не коммитьте пароли от email в git
- Используйте переменные окружения
- Для Gmail используйте App Password, а не обычный пароль
- Регулярно меняйте пароли

