#!/usr/bin/expect -f

# Проверка конфигурации nginx

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка конфигурации nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем конфигурацию вокруг location /api/ и /chef/
puts "\n🔍 Проверка конфигурации location /api/ и /chef/..."
send "sudo sed -n '129,180p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем порядок location блоков
puts "\n🔍 Проверка порядка location блоков..."
send "sudo grep -n 'location' /etc/nginx/sites-available/estenomada | grep -E '(api|chef|^[0-9]+:.*location /)' | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

