#!/usr/bin/expect -f

# Проверка и исправление интерфейса повара

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Проверка и исправление интерфейса повара"
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

# Проверяем логи Django
puts "\n🔍 Проверка логов Django (последние 50 строк)..."
send "sudo tail -50 logs/error.log | grep -A 5 -B 5 'chef' | tail -30\r"
expect "administrator@*"

# Проверяем наличие шаблонов
puts "\n🔍 Проверка шаблонов..."
send "ls -la core/templates/chef/ 2>&1\r"
expect "administrator@*"

# Проверяем доступность /chef/
puts "\n🔍 Проверка доступности /chef/..."
send "curl -s http://localhost:8000/chef/ | head -20\r"
expect "administrator@*"

# Проверяем views
puts "\n🔍 Проверка views..."
send "grep -n 'def chef' core/views.py\r"
expect "administrator@*"

send "exit\r"
expect eof

