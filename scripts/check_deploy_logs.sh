#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_path "/var/www/estenomada/backend"

puts "🔍 Проверка логов деплоя на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем последние логи Django
puts "\n📋 Последние ошибки Django:"
send "sudo tail -100 $backend_path/logs/error.log | tail -30\r"
expect "administrator@*"

# Проверяем статус сервисов
puts "\n📊 Статус сервисов:"
send "sudo systemctl status estenomada-backend --no-pager | head -15\r"
expect "administrator@*"

send "sudo systemctl status estenomada-frontend --no-pager | head -15\r"
expect "administrator@*"

# Проверяем последние изменения в backend
puts "\n📁 Последние изменения в backend:"
send "cd $backend_path && sudo ls -lah | tail -10\r"
expect "administrator@*"

# Проверяем venv
puts "\n🐍 Проверка venv:"
send "cd $backend_path && sudo ls -lah venv/bin/ | grep -E 'python|pip' | head -5\r"
expect "administrator@*"

# Проверяем, работает ли Django
puts "\n🧪 Тест Django:"
send "cd $backend_path && sudo -u www-data venv/bin/python manage.py check 2>&1 | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

