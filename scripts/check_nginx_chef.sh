#!/usr/bin/expect -f

# Проверка конфигурации nginx для /chef/

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка конфигурации nginx для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем конфигурацию nginx
puts "\n🔍 Проверка конфигурации nginx..."
send "sudo cat /etc/nginx/sites-available/estenomada | grep -A 10 -B 5 'chef'\r"
expect "administrator@*"

# Проверяем все location блоки
puts "\n🔍 Проверка location блоков..."
send "sudo cat /etc/nginx/sites-available/estenomada | grep -n 'location'\r"
expect "administrator@*"

# Проверяем, что Django доступен
puts "\n🔍 Проверка доступности Django на /chef/..."
send "curl -I http://localhost:8000/chef/ 2>&1 | head -5\r"
expect "administrator@*"

send "exit\r"
expect eof

