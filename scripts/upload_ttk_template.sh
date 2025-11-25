#!/usr/bin/expect -f

# Загрузка исправленного шаблона ttk_view.html

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Загрузка исправленного шаблона"
puts "=========================================="

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/templates/chef/ttk_view.html $server:/tmp/ttk_view.html
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
puts "\n📝 Копирование шаблона..."
send "sudo cp /tmp/ttk_view.html /var/www/estenomada/backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"

# Устанавливаем права
puts "\n🔐 Установка прав..."
send "sudo chown www-data:www-data /var/www/estenomada/backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"
send "sudo chmod 644 /var/www/estenomada/backend/core/templates/chef/ttk_view.html\r"
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
puts "=========================================="
