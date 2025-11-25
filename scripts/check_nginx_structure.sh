#!/usr/bin/expect -f

# Проверка структуры nginx конфигурации

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка структуры nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем структуру файла
puts "\n🔍 Проверка структуры файла..."
send "sudo grep -n 'server {' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем, в каком server блоке находится location для chef
puts "\n🔍 Проверка location для chef..."
send "sudo awk '/server {/,/^}/ {if (/location.*chef/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем порядок location в HTTPS блоке
puts "\n🔍 Проверка порядка location в HTTPS блоке..."
send "sudo awk '/listen 443/,/^}/ {if (/location/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada | head -20\r"
expect "administrator@*"

# Проверяем, есть ли location / перед location для chef
puts "\n🔍 Проверка порядка location / и chef..."
send "sudo awk '/listen 443/,/^}/ {if (/location/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada | grep -E '(chef|^[0-9]+:.*location /)' | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

