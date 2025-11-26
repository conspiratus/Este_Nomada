#!/usr/bin/expect -f

# Создание миграции для новых моделей ТТК

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Создание миграции для новых моделей ТТК"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Активируем venv
puts "\n🐍 Активация виртуального окружения..."
send "cd /var/www/estenomada/backend && source venv/bin/activate\r"
expect "administrator@*"

# Создаём миграцию
puts "\n📝 Создание миграции..."
send "python manage.py makemigrations core\r"
expect "administrator@*"

# Применяем миграцию
puts "\n🔄 Применение миграции..."
send "python manage.py migrate core\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "=========================================="

