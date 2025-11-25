#!/usr/bin/expect -f

# Прямое тестирование /chef/

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Прямое тестирование /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем /en/chef/ (с слэшем)
puts "\n🔍 Проверка /en/chef/..."
send "curl -s -L http://127.0.0.1/en/chef/ -H 'Host: estenomada.es' 2>&1 | head -30\r"
expect "administrator@*"

# Проверяем Django напрямую
puts "\n🔍 Проверка Django /chef/..."
send "curl -s http://localhost:8000/chef/ 2>&1 | head -20\r"
expect "administrator@*"

# Проверяем логи nginx
puts "\n🔍 Проверка логов nginx..."
send "sudo tail -10 /var/log/nginx/estenomada_access.log | tail -3\r"
expect "administrator@*"

send "exit\r"
expect eof

