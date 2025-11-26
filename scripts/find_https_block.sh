#!/usr/bin/expect -f

# Поиск HTTPS блока

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Поиск HTTPS блока"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Ищем все server блоки
puts "\n🔍 Поиск всех server блоков..."
send "sudo grep -n 'server {' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Ищем строки с location / в каждом server блоке
puts "\n🔍 Поиск location / в каждом блоке..."
send "sudo grep -n 'location / {' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Читаем весь файл, чтобы понять структуру
puts "\n🔍 Чтение структуры файла..."
send "sudo wc -l /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"
send "sudo sed -n '1,20p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Ищем строку с location /api/ и читаем контекст
puts "\n🔍 Контекст location /api/..."
send "sudo grep -B 5 -A 15 'location /api/' /etc/nginx/sites-available/estenomada | head -25\r"
expect "administrator@*"

send "exit\r"
expect eof

