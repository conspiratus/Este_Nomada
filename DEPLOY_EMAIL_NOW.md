# 🚀 Немедленная настройка Email на Production

## Выполните эту команду на сервере:

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one "cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c && git pull origin feature/personal-cabinet-cart 2>/dev/null || echo 'Git pull skipped' && chmod +x scripts/setup_email_auto.sh && ./scripts/setup_email_auto.sh"
```

Или подключитесь к серверу и выполните:

```bash
# 1. Подключитесь к серверу
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one

# 2. Перейдите в директорию проекта
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c

# 3. Обновите код (если нужно)
git pull origin feature/personal-cabinet-cart

# 4. Запустите автоматическую настройку
chmod +x scripts/setup_email_auto.sh
./scripts/setup_email_auto.sh
```

## Что делает скрипт:

✅ Автоматически настраивает `.env` с данными:
- Email: `info@nomadadeleste.com`
- SMTP: `send.one.com:465`
- SSL включен

✅ Создает резервную копию `.env`

✅ Отправляет тестовое письмо на `info@nomadadeleste.com`

✅ Показывает статус настройки

## После выполнения:

1. Проверьте почтовый ящик `info@nomadadeleste.com`
2. Должно прийти тестовое письмо "✅ Email настроен успешно"
3. Если письмо не пришло, проверьте логи: `tail -f backend/logs/django.log`

## Проверка настроек:

```bash
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c/backend
cat .env | grep EMAIL
```

Должно быть:
```
EMAIL_HOST=send.one.com
EMAIL_PORT=465
EMAIL_USE_SSL=True
EMAIL_HOST_USER=info@nomadadeleste.com
DEFAULT_FROM_EMAIL=info@nomadadeleste.com
```

## Готово! 🎉

Email настроен и готов к использованию для:
- ✅ Подтверждения регистрации пользователей
- ✅ Уведомлений о заказах
- ✅ Восстановления паролей
- ✅ Любых других писем через Django

