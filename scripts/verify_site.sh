#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "🔍 Проверка работы сайта..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем статус сервисов
puts "\n📊 Статус сервисов:"
send "sudo systemctl is-active estenomada-backend estenomada-frontend\r"
expect "administrator@*"

# Проверяем порты
puts "\n🔌 Проверка портов:"
send "sudo ss -tlnp | grep -E '8000|3000'\r"
expect "administrator@*"

# Тестируем подключение
puts "\n🧪 Тест подключения:"
send "curl -I http://localhost:8000 2>&1 | head -3\r"
expect "administrator@*"

send "curl -I http://localhost:3000 2>&1 | head -3\r"
expect "administrator@*"

send "exit\r"
expect eof

