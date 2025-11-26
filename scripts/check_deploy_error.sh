#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_path "/var/www/estenomada/backend"

puts "🔍 Проверка последних ошибок деплоя..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем последние логи systemd для сервисов
puts "\n📋 Логи estenomada-backend:"
send "sudo journalctl -u estenomada-backend -n 50 --no-pager | tail -30\r"
expect "administrator@*"

puts "\n📋 Логи estenomada-frontend:"
send "sudo journalctl -u estenomada-frontend -n 50 --no-pager | tail -30\r"
expect "administrator@*"

# Проверяем последние ошибки в логах Django
puts "\n📋 Последние ошибки Django:"
send "sudo tail -50 $backend_path/logs/error.log 2>/dev/null | tail -20 || echo 'Лог не найден'\r"
expect "administrator@*"

# Проверяем статус сервисов
puts "\n📊 Статус сервисов:"
send "sudo systemctl status estenomada-backend --no-pager -l | head -20\r"
expect "administrator@*"

send "sudo systemctl status estenomada-frontend --no-pager -l | head -20\r"
expect "administrator@*"

# Проверяем, есть ли файлы после деплоя
puts "\n📁 Проверка файлов:"
send "cd $backend_path && ls -lah manage.py venv/bin/python 2>&1\r"
expect "administrator@*"

# Проверяем переменные окружения
puts "\n🔧 Проверка переменных окружения:"
send "cd $backend_path && sudo -u www-data bash -c 'source venv/bin/activate && python -c \"import os; print(\\\"DJANGO_SETTINGS_MODULE:\\\", os.environ.get(\\\"DJANGO_SETTINGS_MODULE\\\", \\\"NOT SET\\\"))\"' 2>&1\r"
expect "administrator@*"

send "exit\r"
expect eof

