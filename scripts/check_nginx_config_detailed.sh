#!/usr/bin/expect -f

# Детальная проверка конфигурации nginx

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Детальная проверка конфигурации nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем, что конфигурация содержит location для chef
puts "\n🔍 Проверка наличия location для chef в файле..."
send "sudo grep -n 'location.*chef' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем активную конфигурацию nginx
puts "\n🔍 Проверка активной конфигурации nginx..."
send "sudo nginx -T 2>&1 | grep -B 2 -A 12 'location.*chef' | head -40\r"
expect "administrator@*"

# Проверяем, какой server блок активен для estenomada.es
puts "\n🔍 Проверка server блоков..."
send "sudo nginx -T 2>&1 | grep -A 5 'server_name.*estenomada.es' | head -20\r"
expect "administrator@*"

# Проверяем порядок location в активной конфигурации
puts "\n🔍 Проверка порядка location..."
send "sudo nginx -T 2>&1 | awk '/server_name.*estenomada.es/,/^}/ {if (/location/) print NR\": \"\$0}' | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

