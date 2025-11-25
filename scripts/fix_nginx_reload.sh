#!/usr/bin/expect -f

# Полный перезапуск nginx и проверка

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Полный перезапуск nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем синтаксис
puts "\n🔍 Проверка синтаксиса..."
send "sudo nginx -t\r"
expect "administrator@*"

# Останавливаем nginx
puts "\n🛑 Остановка nginx..."
send "sudo systemctl stop nginx\r"
expect "administrator@*"

# Запускаем nginx
puts "\n▶️  Запуск nginx..."
send "sudo systemctl start nginx\r"
expect "administrator@*"

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sudo systemctl status nginx --no-pager | head -10\r"
expect "administrator@*"

# Проверяем активную конфигурацию
puts "\n🔍 Проверка активной конфигурации для /en/chef/..."
send "sudo nginx -T 2>&1 | grep -A 10 'location.*en.*chef' | head -15\r"
expect "administrator@*"

# Тестируем запрос
puts "\n🔍 Тестирование запроса..."
send "curl -s -o /dev/null -w '%{http_code}' -H 'Host: estenomada.es' http://127.0.0.1/en/chef/\r"
expect "administrator@*"

send "exit\r"
expect eof

