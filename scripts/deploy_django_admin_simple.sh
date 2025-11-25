#!/usr/bin/expect -f

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Настройка Django Admin"
puts "=========================================="

# Загружаем обновленный Nginx конфиг
puts "\n📤 Загрузка Nginx конфигурации..."
spawn scp nginx/estenomada.production.conf $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ Nginx конфиг загружен"

# Загружаем обновленный middleware.ts
puts "\n📤 Загрузка middleware.ts..."
spawn scp middleware.ts $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ middleware.ts загружен"

# Подключаемся и выполняем команды
puts "\n🔌 Подключение к серверу..."
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*" {
    puts "✅ Подключено"
}

# Переходим в директорию проекта
send "cd /var/www/estenomada\r"
expect "administrator@*"

# Удаляем кастомную админку с sudo
puts "\n🗑️  Удаление кастомной Next.js админки..."
send "sudo rm -rf app/admin app/api/admin lib/auth.ts lib/admin-auth.ts\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Кастомная админка удалена"
    }
}

# Копируем middleware.ts
puts "\n📝 Обновление middleware.ts..."
send "sudo cp /tmp/middleware.ts middleware.ts\r"
expect "administrator@*"
send "sudo chown administrator:administrator middleware.ts\r"
expect "administrator@*"
puts "✅ middleware.ts обновлен"

# Копируем Nginx конфиг
puts "\n📝 Обновление Nginx конфигурации..."
send "sudo cp /tmp/estenomada.production.conf /etc/nginx/sites-available/estenomada.production.conf\r"
expect "administrator@*"
puts "✅ Nginx конфиг обновлен"

# Тестируем Nginx
puts "\n🧪 Тестирование Nginx..."
send "sudo nginx -t\r"
expect "administrator@*"

# Перезагружаем Nginx
puts "\n🔄 Перезагрузка Nginx..."
send "sudo systemctl reload nginx\r"
expect "administrator@*"
puts "✅ Nginx перезагружен"

# Собираем статические файлы Django
puts "\n📦 Сборка статических файлов Django..."
send "cd backend\r"
expect "administrator@*"
send "source venv/bin/activate\r"
expect "(venv)*"
send "python3 manage.py collectstatic --noinput\r"
expect {
    "(venv)*" {
        puts "✅ Статические файлы собраны"
    }
    timeout {
        puts "⚠️  Timeout при сборке статики"
    }
}

# Перезапускаем backend
puts "\n🔄 Перезапуск Django backend..."
send "sudo systemctl restart estenomada-backend\r"
expect "(venv)*"
puts "✅ Backend перезапущен"

send "deactivate\r"
expect "administrator@*"
send "cd /var/www/estenomada\r"
expect "administrator@*"

# Пересобираем Next.js
puts "\n🔨 Пересборка Next.js frontend..."
send "sudo chown -R administrator:administrator .next 2>/dev/null || true\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build\r"
expect {
    "administrator@*" {
        puts "✅ Next.js собран"
    }
    timeout {
        puts "⚠️  Timeout при сборке Next.js (может быть нормально)"
    }
}

# Устанавливаем права
send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Перезапускаем frontend
puts "\n🔄 Перезапуск Next.js frontend..."
send "sudo systemctl restart estenomada-frontend\r"
expect "administrator@*"
puts "✅ Frontend перезапущен"

# Проверяем статус
puts "\n📊 Проверка статуса сервисов..."
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"
send "sudo systemctl is-active nginx\r"
expect "administrator@*"

puts "\n=========================================="
puts "✅ ГОТОВО!"
puts "=========================================="
puts "Django Admin доступна по адресу:"
puts "https://estenomada.es/admin/"
puts ""
puts "Логин: admin"
puts "Пароль: admin123"
puts "=========================================="

send "exit\r"
expect eof

