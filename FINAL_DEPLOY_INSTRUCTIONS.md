# 🚀 ФИНАЛЬНЫЙ ДЕПЛОЙ - Запустите на вашем компьютере

## Проблема с DNS

Хост `ssh.czjey8yl0.service.one` не разрешается через DNS в моем окружении. Это может быть внутренний хост one.com, доступный только из определенной сети.

## Решение: Запустите скрипт на вашем компьютере

### Вариант 1: Expect скрипт (рекомендуется)

```bash
cd /Users/conspiratus/Projects/Este_Nomada
chmod +x scripts/deploy_personal_cabinet_final.sh
./scripts/deploy_personal_cabinet_final.sh
```

### Вариант 2: Одна команда

```bash
cd /Users/conspiratus/Projects/Este_Nomada && expect << 'EXPECT_SCRIPT'
set timeout 1800
set password "Drozdofil12345!"
set host "ssh.czjey8yl0.service.one"
set user "czjey8yl0_ssh"
set remote_dir "/customers/d/9/4/czjey8yl0/webroots/17a5d75c"

spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir} && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart && cd backend && source venv/bin/activate && pip install -q geopy markdown && python manage.py migrate --noinput && if [ -f .env ]; then cp .env .env.backup.\$(date +%Y%m%d_%H%M%S); fi && sed -i.bak '/^EMAIL_/d' .env 2>/dev/null || true && sed -i.bak '/^DEFAULT_FROM_EMAIL/d' .env 2>/dev/null || true && sed -i.bak '/^SERVER_EMAIL/d' .env 2>/dev/null || true && echo '' >> .env && echo '# Email Settings' >> .env && echo 'EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend' >> .env && echo 'EMAIL_HOST=send.one.com' >> .env && echo 'EMAIL_PORT=465' >> .env && echo 'EMAIL_USE_TLS=False' >> .env && echo 'EMAIL_USE_SSL=True' >> .env && echo 'EMAIL_HOST_USER=info@nomadadeleste.com' >> .env && echo 'EMAIL_HOST_PASSWORD=Drozdofil12345!' >> .env && echo 'DEFAULT_FROM_EMAIL=info@nomadadeleste.com' >> .env && echo 'SERVER_EMAIL=info@nomadadeleste.com' >> .env && if ! grep -q '^ENCRYPTION_KEY=' .env 2>/dev/null; then ENC_KEY=\$(python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'); echo \"ENCRYPTION_KEY=\$ENC_KEY\" >> .env; fi && python manage.py collectstatic --noinput && sudo systemctl restart estenomada-backend && python manage.py shell -c \"from django.core.mail import send_mail; from django.conf import settings; send_mail('✅ Деплой завершен', 'Деплой успешно завершен!', settings.DEFAULT_FROM_EMAIL, [settings.EMAIL_HOST_USER], fail_silently=False)\""

expect {
    "password:" { send "${password}\r"; exp_continue }
    "(yes/no" { send "yes\r"; exp_continue }
    eof { exit }
}
EXPECT_SCRIPT
```

## Что будет сделано:

✅ Переключение на бранч `feature/personal-cabinet-cart`  
✅ Обновление кода из GitHub  
✅ Установка зависимостей (geopy, markdown)  
✅ Применение миграций  
✅ Настройка email (info@nomadadeleste.com)  
✅ Генерация ENCRYPTION_KEY  
✅ Сбор статики  
✅ Перезапуск сервиса  
✅ Отправка тестового письма  

## После выполнения:

1. Проверьте почту `info@nomadadeleste.com`
2. Проверьте сайт: https://estenomada.es/ru/order
3. Настройте доставку: /admin/core/deliverysettings/

## Все готово!

Скрипты созданы и запушены в GitHub. Запустите на вашем компьютере - там DNS должен работать правильно.

