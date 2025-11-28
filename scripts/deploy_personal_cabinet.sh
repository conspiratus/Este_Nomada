#!/bin/bash
# Полный деплой личного кабинета и корзины на production
# Использование: ./scripts/deploy_personal_cabinet.sh

set -e

SERVER="czjey8yl0_ssh@ssh.czjey8yl0.service.one"
REMOTE_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"
PASSWORD="Drozdofil12345!"

echo "🚀 Деплой личного кабинета и корзины на production"
echo "=================================================="

# 1. Обновление кода из бранча
echo ""
echo "📥 Обновление кода из бранча feature/personal-cabinet-cart..."
expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 2. Установка зависимостей backend
echo ""
echo "📦 Установка зависимостей backend..."
expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && pip install -q geopy markdown"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 3. Применение миграций
echo ""
echo "🗄️  Применение миграций..."
expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py migrate --noinput"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 4. Настройка email
echo ""
echo "📧 Настройка email..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && if [ -f .env ]; then cp .env .env.backup.\$(date +%Y%m%d_%H%M%S); fi && sed -i.bak '/^EMAIL_/d' .env 2>/dev/null || true && sed -i.bak '/^DEFAULT_FROM_EMAIL/d' .env 2>/dev/null || true && sed -i.bak '/^SERVER_EMAIL/d' .env 2>/dev/null || true && cat >> .env << 'ENVEOF'

# Email Settings (one.com SMTP)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=send.one.com
EMAIL_PORT=465
EMAIL_USE_TLS=False
EMAIL_USE_SSL=True
EMAIL_HOST_USER=info@nomadadeleste.com
EMAIL_HOST_PASSWORD=Drozdofil12345!
DEFAULT_FROM_EMAIL=info@nomadadeleste.com
SERVER_EMAIL=info@nomadadeleste.com
ENVEOF
"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 5. Генерация ENCRYPTION_KEY если нет
echo ""
echo "🔐 Проверка ENCRYPTION_KEY..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && if ! grep -q '^ENCRYPTION_KEY=' .env 2>/dev/null; then python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())' >> /tmp/enc_key.txt && echo 'ENCRYPTION_KEY='\$(cat /tmp/enc_key.txt) >> .env && rm /tmp/enc_key.txt && echo 'Ключ сгенерирован'; else echo 'Ключ уже есть'; fi"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 6. Создание настроек доставки
echo ""
echo "🚚 Проверка настроек доставки..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py shell -c \"from core.models import DeliverySettings; s = DeliverySettings.get_settings(); print(f'Настройки доставки: ID={s.id}')\""
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 7. Сбор статики
echo ""
echo "📦 Сбор статических файлов..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py collectstatic --noinput"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 8. Перезапуск сервиса
echo ""
echo "🔄 Перезапуск сервиса..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "sudo systemctl restart estenomada-backend"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# 9. Тест отправки email
echo ""
echo "🧪 Тестирование email..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py shell -c \"from django.core.mail import send_mail; from django.conf import settings; send_mail('✅ Деплой завершен - Este Nómada', 'Деплой личного кабинета успешно завершен!', settings.DEFAULT_FROM_EMAIL, [settings.EMAIL_HOST_USER], fail_silently=False); print('Тестовое письмо отправлено')\""
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo ""
echo "✅ Деплой завершён!"
echo ""
echo "📋 Что сделано:"
echo "   1. ✅ Код обновлен из бранча feature/personal-cabinet-cart"
echo "   2. ✅ Зависимости установлены (geopy, markdown)"
echo "   3. ✅ Миграции применены"
echo "   4. ✅ Email настроен (info@nomadadeleste.com)"
echo "   5. ✅ ENCRYPTION_KEY сгенерирован (если нужно)"
echo "   6. ✅ Настройки доставки созданы"
echo "   7. ✅ Статические файлы собраны"
echo "   8. ✅ Сервис перезапущен"
echo "   9. ✅ Тестовое письмо отправлено"
echo ""
echo "📧 Проверьте почтовый ящик info@nomadadeleste.com"
echo "🌐 Проверьте страницу заказов: https://estenomada.es/ru/order"
echo "⚙️  Настройте доставку в админке: /admin/core/deliverysettings/"

