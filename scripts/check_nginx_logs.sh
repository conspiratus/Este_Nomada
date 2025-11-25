#!/usr/bin/expect -f

# Проверка логов nginx

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка логов nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем error логи
puts "\n🔍 Проверка error логов..."
send "sudo tail -30 /var/log/nginx/estenomada_error.log | grep -i chef\r"
expect "administrator@*"

# Проверяем access логи
puts "\n🔍 Проверка access логов для /chef..."
send "sudo tail -20 /var/log/nginx/estenomada_access.log | grep chef\r"
expect "administrator@*"

# Проверяем, что Django отвечает на /chef/
puts "\n🔍 Проверка Django /chef/..."
send "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/chef/\r"
expect "administrator@*"

# Проверяем конфигурацию nginx для /en/chef/
puts "\n🔍 Проверка конфигурации nginx..."
send "sudo nginx -T 2>&1 | grep -A 10 'location.*chef' | head -30\r"
expect "administrator@*"

# Тестируем запрос через nginx
puts "\n🔍 Тестирование запроса /en/chef/ через nginx..."
send "curl -s -o /dev/null -w '%{http_code}' -H 'Host: estenomada.es' http://127.0.0.1/en/chef/\r"
expect "administrator@*"

send "exit\r"
expect eof

