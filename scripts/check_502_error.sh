#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "🔍 Проверка 502 Bad Gateway..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем статус сервисов
puts "\n📊 Статус сервисов:"
send "sudo systemctl status estenomada-backend --no-pager | head -15\r"
expect "administrator@*"

send "sudo systemctl status estenomada-frontend --no-pager | head -15\r"
expect "administrator@*"

# Проверяем, слушают ли сервисы порты
puts "\n🔌 Проверка портов:"
send "sudo netstat -tlnp | grep -E '8000|3000' || sudo ss -tlnp | grep -E '8000|3000'\r"
expect "administrator@*"

# Проверяем последние логи Nginx
puts "\n📋 Последние ошибки Nginx:"
send "sudo tail -30 /var/log/nginx/error.log | grep -i '502\\|upstream\\|connect'\r"
expect "administrator@*"

# Проверяем логи backend
puts "\n📋 Последние логи backend:"
send "sudo journalctl -u estenomada-backend -n 30 --no-pager | tail -20\r"
expect "administrator@*"

# Проверяем логи frontend
puts "\n📋 Последние логи frontend:"
send "sudo journalctl -u estenomada-frontend -n 30 --no-pager | tail -20\r"
expect "administrator@*"

# Пробуем подключиться к сервисам напрямую
puts "\n🧪 Тест подключения:"
send "curl -I http://localhost:8000 2>&1 | head -5\r"
expect "administrator@*"

send "curl -I http://localhost:3000 2>&1 | head -5\r"
expect "administrator@*"

# Проверяем конфигурацию Nginx
puts "\n⚙️  Проверка конфигурации Nginx:"
send "sudo nginx -t\r"
expect "administrator@*"

send "exit\r"
expect eof

