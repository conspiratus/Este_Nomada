#!/usr/bin/expect -f

# Загрузка исправленного views.py

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Загрузка исправленного views.py"
puts "=========================================="

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/views.py $server:/tmp/views.py
expect {
    "password:" {
        send "$password\r"
    }
}

expect eof

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Останавливаем Django
puts "\n🛑 Остановка Django..."
send "sudo systemctl stop estenomada-backend\r"
expect "administrator@*"

# Копируем файл
puts "\n📝 Копирование views.py..."
send "sudo cp /tmp/views.py /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"

# Устанавливаем права
puts "\n🔐 Установка прав..."
send "sudo chown www-data:www-data /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"
send "sudo chmod 644 /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"

# Проверяем файл
puts "\n🔍 Проверка файла..."
send "sudo grep -A 5 'with open(ttk.ttk_file.path' /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"

# Запускаем Django
puts "\n▶️  Запуск Django..."
send "sudo systemctl start estenomada-backend\r"
expect "administrator@*"

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь открытие ТТК файла"
puts "=========================================="

