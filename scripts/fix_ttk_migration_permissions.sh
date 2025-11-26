#!/usr/bin/expect -f

# Исправление прав и создание миграции

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление прав и создание миграции"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Устанавливаем права на директорию migrations
puts "\n🔐 Установка прав на migrations..."
send "sudo chown -R administrator:administrator /var/www/estenomada/backend/core/migrations/\r"
expect "administrator@*"
send "sudo chmod -R 755 /var/www/estenomada/backend/core/migrations/\r"
expect "administrator@*"

# Активируем venv и создаём миграцию
puts "\n🐍 Создание миграции..."
send "cd /var/www/estenomada/backend && source venv/bin/activate && python manage.py makemigrations core\r"
expect "administrator@*"

# Применяем миграцию
puts "\n🔄 Применение миграции..."
send "python manage.py migrate core\r"
expect "administrator@*"

# Возвращаем права
puts "\n🔐 Возврат прав..."
send "sudo chown -R www-data:www-data /var/www/estenomada/backend/core/\r"
expect "administrator@*"

# Перезапускаем Django
puts "\n🔄 Перезапуск Django..."
send "sudo systemctl restart estenomada-backend\r"
expect "administrator@*"

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "=========================================="

