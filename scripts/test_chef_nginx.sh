#!/usr/bin/expect -f

# Тестирование nginx для /chef/

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Тестирование nginx для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем доступность через nginx
puts "\n🔍 Проверка /en/chef через nginx..."
send "curl -s http://127.0.0.1/en/chef -H 'Host: estenomada.es' 2>&1 | head -30\r"
expect "administrator@*"

# Проверяем логи
puts "\n🔍 Проверка последних логов..."
send "sudo tail -3 /var/log/nginx/estenomada_access.log | grep chef\r"
expect "administrator@*"

send "exit\r"
expect eof

