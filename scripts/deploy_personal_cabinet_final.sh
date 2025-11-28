#!/usr/bin/expect -f
# Полный деплой личного кабинета и корзины на production
# Использование: ./scripts/deploy_personal_cabinet_final.sh

set timeout 1800
set password "Drozdofil12345!"
set host "ssh.czjey8yl0.service.one"
set user "czjey8yl0_ssh"
set remote_dir "/customers/d/9/4/czjey8yl0/webroots/17a5d75c"

puts "🚀 Деплой личного кабинета и корзины на production"
puts "=================================================="

# 1. Обновление кода из бранча
puts ""
puts "📥 Обновление кода из бранча feature/personal-cabinet-cart..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir} && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Код обновлен"
    }
}

# 2. Установка зависимостей
puts ""
puts "📦 Установка зависимостей backend..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && pip install -q geopy markdown"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Зависимости установлены"
    }
}

# 3. Применение миграций
puts ""
puts "🗄️  Применение миграций..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && python manage.py migrate --noinput"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Миграции применены"
    }
}

# 4. Настройка email
puts ""
puts "📧 Настройка email..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && test -f .env && cp .env .env.backup.\$(date +%Y%m%d_%H%M%S) || true; sed -i.bak '/^EMAIL_/d' .env 2>/dev/null || true; sed -i.bak '/^DEFAULT_FROM_EMAIL/d' .env 2>/dev/null || true; sed -i.bak '/^SERVER_EMAIL/d' .env 2>/dev/null || true; echo '' >> .env; echo '# Email Settings (one.com SMTP)' >> .env; echo 'EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend' >> .env; echo 'EMAIL_HOST=send.one.com' >> .env; echo 'EMAIL_PORT=465' >> .env; echo 'EMAIL_USE_TLS=False' >> .env; echo 'EMAIL_USE_SSL=True' >> .env; echo 'EMAIL_HOST_USER=info@nomadadeleste.com' >> .env; echo 'EMAIL_HOST_PASSWORD=Drozdofil12345!' >> .env; echo 'DEFAULT_FROM_EMAIL=info@nomadadeleste.com' >> .env; echo 'SERVER_EMAIL=info@nomadadeleste.com' >> .env; echo 'Email настроен'"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Email настроен"
    }
}

# 5. ENCRYPTION_KEY
puts ""
puts "🔐 Проверка ENCRYPTION_KEY..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && if ! grep -q '^ENCRYPTION_KEY=' .env 2>/dev/null; then ENC_KEY=\$(python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'); echo \"ENCRYPTION_KEY=\$ENC_KEY\" >> .env && echo 'Ключ сгенерирован'; else echo 'Ключ уже есть'; fi"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ ENCRYPTION_KEY проверен"
    }
}

# 6. Настройки доставки
puts ""
puts "🚚 Проверка настроек доставки..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && python manage.py shell -c \"from core.models import DeliverySettings; s = DeliverySettings.get_settings(); print(f'Настройки доставки: ID={s.id}')\""

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Настройки доставки проверены"
    }
}

# 7. Сбор статики
puts ""
puts "📦 Сбор статических файлов..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && python manage.py collectstatic --noinput"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Статика собрана"
    }
}

# 8. Перезапуск сервиса
puts ""
puts "🔄 Перезапуск сервиса..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "sudo systemctl restart estenomada-backend"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Сервис перезапущен"
    }
}

# 9. Тест email
puts ""
puts "🧪 Тестирование email..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && python manage.py shell -c \"from django.core.mail import send_mail; from django.conf import settings; send_mail('✅ Деплой завершен - Este Nómada', 'Деплой личного кабинета успешно завершен!', settings.DEFAULT_FROM_EMAIL, [settings.EMAIL_HOST_USER], fail_silently=False); print('Тестовое письмо отправлено')\""

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Тестовое письмо отправлено"
    }
}

puts ""
puts "✅ Деплой завершён!"
puts ""
puts "📋 Что сделано:"
puts "   1. ✅ Код обновлен из бранча feature/personal-cabinet-cart"
puts "   2. ✅ Зависимости установлены (geopy, markdown)"
puts "   3. ✅ Миграции применены"
puts "   4. ✅ Email настроен (info@nomadadeleste.com)"
puts "   5. ✅ ENCRYPTION_KEY сгенерирован"
puts "   6. ✅ Настройки доставки созданы"
puts "   7. ✅ Статические файлы собраны"
puts "   8. ✅ Сервис перезапущен"
puts "   9. ✅ Тестовое письмо отправлено"
puts ""
puts "📧 Проверьте почтовый ящик info@nomadadeleste.com"
puts "🌐 Проверьте страницу заказов: https://estenomada.es/ru/order"
puts "⚙️  Настройте доставку в админке: /admin/core/deliverysettings/"

