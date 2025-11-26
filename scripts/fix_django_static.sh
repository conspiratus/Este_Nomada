#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Сборка статических файлов Django"
puts "=========================================="

spawn ssh $server

expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*" {
    puts "✅ Подключено"
}

# Переходим в backend
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"

# Создаем директорию для логов с правильными правами
puts "\n📁 Создание директории для логов..."
send "sudo mkdir -p logs\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo chown -R www-data:www-data logs\r"
expect "administrator@*"
send "sudo chmod -R 755 logs\r"
expect "administrator@*"
puts "✅ Директория логов настроена"

# Создаем директорию staticfiles с правильными правами
puts "\n📁 Создание директории staticfiles..."
send "sudo mkdir -p staticfiles\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data staticfiles\r"
expect "administrator@*"
puts "✅ Директория staticfiles настроена"

# Активируем виртуальное окружение
puts "\n🔌 Активация виртуального окружения..."
send "source venv/bin/activate\r"
expect "(venv)*"

# Собираем статические файлы с sudo (от www-data)
puts "\n📦 Сборка статических файлов Django..."
send "sudo -u www-data venv/bin/python3 manage.py collectstatic --noinput\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "(venv)*" {
        puts "✅ Статические файлы собраны"
    }
    timeout {
        puts "⚠️  Timeout при сборке статики"
    }
}

# Проверяем, что файлы созданы
puts "\n🔍 Проверка статических файлов..."
send "ls -la staticfiles/admin/css/ | head -10\r"
expect "(venv)*"

# Устанавливаем правильные права
puts "\n🔧 Установка прав доступа..."
send "sudo chown -R www-data:www-data staticfiles\r"
expect "(venv)*"
send "sudo chmod -R 755 staticfiles\r"
expect "(venv)*"
puts "✅ Права установлены"

# Перезапускаем backend
puts "\n🔄 Перезапуск Django backend..."
send "sudo systemctl restart estenomada-backend\r"
expect "(venv)*"
send "sleep 3\r"
expect "(venv)*"
send "sudo systemctl status estenomada-backend --no-pager -l | head -15\r"
expect "(venv)*"
puts "✅ Backend перезапущен"

# Проверяем Nginx
puts "\n🔍 Проверка Nginx конфигурации для /static/..."
send "sudo nginx -t\r"
expect "(venv)*"

puts "\n=========================================="
puts "✅ ГОТОВО!"
puts "=========================================="
puts "Статические файлы Django собраны и доступны."
puts "Попробуй обновить страницу: https://estenomada.es/admin/"
puts "=========================================="

send "exit\r"
expect eof

