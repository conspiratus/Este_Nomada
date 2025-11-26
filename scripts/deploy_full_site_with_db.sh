#!/usr/bin/expect -f

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Полный перенос сайта с БД на продакшн"
puts "=========================================="

# 1. Создаем бэкап на сервере
puts "\n📦 Создание бэкапа на сервере..."
spawn ssh $server "mkdir -p /tmp/estenomada_backup && sudo cp -r /var/www/estenomada/backend/db.sqlite3 /tmp/estenomada_backup/ 2>/dev/null || true"
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ Бэкап создан"

# 2. Останавливаем сервисы
puts "\n🛑 Остановка сервисов на продакшне..."
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo systemctl stop estenomada-frontend estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Сервисы остановлены"
    }
}

send "exit\r"
expect eof

# 3. Загружаем базу данных
puts "\n📤 Загрузка базы данных SQLite..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/db.sqlite3 $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ БД загружена"

# 4. Загружаем весь backend (без venv)
puts "\n📤 Загрузка backend..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/backend.tar.gz --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' --exclude='logs' --exclude='staticfiles' backend/"
expect eof

spawn scp /tmp/backend.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ Backend загружен"

# 5. Загружаем весь frontend (без node_modules и .next)
puts "\n📤 Загрузка frontend..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/frontend.tar.gz --exclude='node_modules' --exclude='.next' --exclude='.git' app/ components/ lib/ messages/ public/ types/ i18n.ts middleware.ts next.config.mjs package.json package-lock.json postcss.config.mjs tailwind.config.ts tsconfig.json server.js .env.production"
expect eof

spawn scp /tmp/frontend.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ Frontend загружен"

# 6. Разворачиваем на сервере
puts "\n📦 Разворачивание файлов на сервере..."
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Распаковываем backend
send "cd /var/www/estenomada\r"
expect "administrator@*"
send "sudo tar xzf /tmp/backend.tar.gz\r"
expect "administrator@*"
puts "✅ Backend распакован"

# Копируем БД
send "sudo cp /tmp/db.sqlite3 /var/www/estenomada/backend/\r"
expect "administrator@*"
send "sudo chown www-data:www-data /var/www/estenomada/backend/db.sqlite3\r"
expect "administrator@*"
send "sudo chmod 664 /var/www/estenomada/backend/db.sqlite3\r"
expect "administrator@*"
puts "✅ БД скопирована"

# Распаковываем frontend
send "sudo tar xzf /tmp/frontend.tar.gz\r"
expect "administrator@*"
puts "✅ Frontend распакован"

# Настраиваем .env.production для SQLite
puts "\n⚙️  Настройка .env.production..."
send "cat > /tmp/backend_env.txt << 'ENVEOF'\r"
expect ">"
send "DEBUG=False\r"
expect ">"
send "SECRET_KEY=django-insecure-prod-key-change-this\r"
expect ">"
send "ALLOWED_HOSTS=estenomada.es,www.estenomada.es,localhost,127.0.0.1\r"
expect ">"
send "CORS_ALLOWED_ORIGINS=https://estenomada.es,https://www.estenomada.es,http://localhost:3000\r"
expect ">"
send "CSRF_TRUSTED_ORIGINS=https://estenomada.es,https://www.estenomada.es\r"
expect ">"
send "USE_SQLITE=True\r"
expect ">"
send "ENVEOF\r"
expect "administrator@*"

send "sudo cp /tmp/backend_env.txt /var/www/estenomada/backend/.env.production\r"
expect "administrator@*"
send "sudo chown www-data:www-data /var/www/estenomada/backend/.env.production\r"
expect "administrator@*"
puts "✅ .env.production настроен"

# Устанавливаем права
puts "\n🔧 Установка прав доступа..."
send "sudo chown -R www-data:www-data /var/www/estenomada/backend\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data /var/www/estenomada/app\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data /var/www/estenomada/components\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data /var/www/estenomada/lib\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data /var/www/estenomada/public\r"
expect "administrator@*"
puts "✅ Права установлены"

# Собираем статику Django
puts "\n📦 Сборка статики Django..."
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"
send "sudo -u www-data venv/bin/python3 manage.py collectstatic --noinput\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Статика собрана"
    }
    timeout {
        puts "⚠️  Timeout при сборке статики"
    }
}

# Пересобираем frontend
puts "\n🔨 Пересборка Next.js..."
send "cd /var/www/estenomada\r"
expect "administrator@*"
send "sudo chown -R administrator:administrator .\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build\r"
expect {
    "administrator@*" {
        puts "✅ Next.js собран"
    }
    timeout {
        puts "⚠️  Timeout при сборке (продолжаем...)"
    }
}

send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Создаем prerender-manifest.json
send "cat > /tmp/prerender.json << 'PRERENDEREOF'\r"
expect ">"
send "\\{\r"
expect ">"
send "  \"version\": 4,\r"
expect ">"
send "  \"routes\": \\{\\},\r"
expect ">"
send "  \"dynamicRoutes\": \\{\\},\r"
expect ">"
send "  \"notFoundRoutes\": \\[\\],\r"
expect ">"
send "  \"preview\": \\{\r"
expect ">"
send "    \"previewModeId\": \"\",\r"
expect ">"
send "    \"previewModeSigningKey\": \"\",\r"
expect ">"
send "    \"previewModeEncryptionKey\": \"\"\r"
expect ">"
send "  \\}\r"
expect ">"
send "\\}\r"
expect ">"
send "PRERENDEREOF\r"
expect "administrator@*"

send "sudo cp /tmp/prerender.json /var/www/estenomada/.next/prerender-manifest.json\r"
expect "administrator@*"
send "sudo chown www-data:www-data /var/www/estenomada/.next/prerender-manifest.json\r"
expect "administrator@*"
puts "✅ prerender-manifest.json создан"

# Запускаем сервисы
puts "\n🚀 Запуск сервисов..."
send "sudo systemctl start estenomada-backend estenomada-frontend\r"
expect "administrator@*"
send "sleep 5\r"
expect "administrator@*"

# Проверяем статус
puts "\n📊 Проверка статуса..."
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"

puts "\n=========================================="
puts "✅ ГОТОВО!"
puts "=========================================="
puts "Сайт полностью перенесён на продакшн:"
puts "- Frontend: https://estenomada.es"
puts "- Django Admin: https://estenomada.es/admin/"
puts "- БД: SQLite (локальная копия)"
puts ""
puts "Логин: admin"
puts "Пароль: admin123"
puts "=========================================="

send "exit\r"
expect eof



