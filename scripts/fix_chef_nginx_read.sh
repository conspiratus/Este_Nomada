#!/usr/bin/expect -f

# Чтение и исправление nginx конфигурации

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Чтение и исправление nginx конфигурации"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Читаем конфигурацию вокруг location /
puts "\n🔍 Чтение конфигурации вокруг location /..."
send "sudo sed -n '140,160p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем, есть ли location для chef после location /api/
puts "\n🔍 Проверка location после /api/..."
send "sudo sed -n '56,80p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем, есть ли location для chef в HTTPS блоке (после строки 126)
puts "\n🔍 Проверка HTTPS блока..."
send "sudo sed -n '126,160p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "exit\r"
expect eof

