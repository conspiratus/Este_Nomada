#!/usr/bin/expect -f

# Загрузка views для chef интерфейса

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Загрузка views для chef"
puts "=========================================="

# Загружаем core/views.py
puts "\n📤 Загрузка core/views.py..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/views.py $server:/tmp/core_views.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $backend_dir\r"
expect "administrator@*"

# Останавливаем Django
puts "\n🛑 Остановка Django..."
send "sudo systemctl stop estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django остановлен"
    }
}

# Копируем файл
puts "\n📥 Копирование файла..."
send "sudo cp /tmp/core_views.py core/views.py\r"
expect "administrator@*"
send "sudo chown www-data:www-data core/views.py\r"
expect "administrator@*"

# Проверяем chef views
puts "\n🔍 Проверка chef views..."
send "grep -n 'def chef' core/views.py | head -5\r"
expect "administrator@*"

# Запускаем Django
puts "\n🚀 Запуск Django..."
send "sudo systemctl start estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django запущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

# Проверяем доступность
puts "\n🔍 Проверка доступности /chef/..."
send "curl -I http://localhost:8000/chef/ 2>&1 | head -3\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/chef/"
puts "=========================================="

