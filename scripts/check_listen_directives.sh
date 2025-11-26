#!/usr/bin/expect -f

# Проверка listen директив

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка listen директив"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Находим server блок с location для chef и проверяем listen
puts "\n🔍 Поиск server блока с location для chef..."
send "sudo awk '/server {/,/^}/ {if (/listen/) listen_line=NR\": \"\$0; if (/location.*chef/) {print \"Found location for chef\"; print \"Listen directive:\", listen_line; exit}}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Читаем весь файл, чтобы понять структуру
puts "\n🔍 Чтение всего файла для понимания структуры..."
send "sudo cat /etc/nginx/sites-available/estenomada | head -50\r"
expect "administrator@*"

# Проверяем, есть ли listen 443 перед location для chef
puts "\n🔍 Проверка listen 443 перед location для chef..."
send "sudo awk 'NR < 142 && /listen.*443/ {print NR\": \"\$0}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем, какой server блок начинается перед строкой 142
puts "\n🔍 Поиск server блоков перед строкой 142..."
send "sudo awk 'NR < 142 && /^server {/ {print NR\": server block starts\"}' /etc/nginx/sites-available/estenomada | tail -1\r"
expect "administrator@*"

# Читаем начало server блока, где находится location для chef
puts "\n🔍 Чтение начала server блока с location для chef..."
send "sudo sed -n '30,50p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "exit\r"
expect eof

