#!/usr/bin/expect -f

# Исправление импорта core.urls

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Исправление импорта core.urls"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $backend_dir\r"
expect "administrator@*"

# Проверяем наличие файла
puts "\n🔍 Проверка файла core/urls.py..."
send "ls -la core/urls.py\r"
expect "administrator@*"

# Проверяем содержимое
puts "\n🔍 Проверка содержимого core/urls.py..."
send "cat core/urls.py\r"
expect "administrator@*"

# Проверяем, что views существуют
puts "\n🔍 Проверка views..."
send "grep -n 'def chef' core/views.py | head -5\r"
expect "administrator@*"

# Перезапускаем Django
puts "\n🔄 Перезапуск Django..."
send "sudo systemctl restart estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django перезапущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 3\r"
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
puts "=========================================="

