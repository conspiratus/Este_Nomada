# ⚡ Быстрая настройка Email - 1 команда

## Выполните эту команду на вашем компьютере:

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one "cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c && git pull origin feature/personal-cabinet-cart 2>/dev/null || echo 'Git pull skipped' && chmod +x scripts/setup_email_on_server.sh && ./scripts/setup_email_on_server.sh"
```

Или подключитесь к серверу и выполните по шагам:

```bash
# 1. Подключитесь к серверу
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one

# 2. Перейдите в директорию проекта
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c

# 3. Обновите код (если нужно)
git pull origin feature/personal-cabinet-cart

# 4. Запустите скрипт настройки
chmod +x scripts/setup_email_on_server.sh
./scripts/setup_email_on_server.sh
```

## ⚠️ ВАЖНО: Сначала создайте почтовый ящик в панели one.com!

**Почту нужно создать в панели управления one.com, а не на сервере!**

См. инструкцию: `CREATE_EMAIL_ACCOUNT.md`

### Быстрая инструкция:

1. Войдите в панель one.com
2. Выберите домен `nomadadeleste.com`
3. Перейдите в раздел **"Email"** или **"Почта"**
4. Создайте почтовый ящик: `info@nomadadeleste.com`
5. Запишите пароль!

## Что нужно будет ввести при запуске скрипта:

1. **Email для отправки писем:** `info@nomadadeleste.com`
2. **Пароль от этого email** (который вы создали в панели one.com)
3. **Email для тестового письма** (опционально, можно пропустить нажав Enter)

## После настройки:

Скрипт автоматически:
- ✅ Настроит `.env` файл с правильными параметрами SMTP one.com
- ✅ Отправит тестовое письмо (если указан email)
- ✅ Покажет статус настройки

## Проверка:

```bash
# Проверьте настройки
cat backend/.env | grep EMAIL

# Должно быть:
# EMAIL_HOST=send.one.com
# EMAIL_PORT=465
# EMAIL_USE_SSL=True
```

## Если скрипт не работает:

См. подробную инструкцию: `DEPLOY_EMAIL_SETUP.md`

