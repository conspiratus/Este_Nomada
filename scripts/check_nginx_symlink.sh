#!/usr/bin/expect -f

# Проверка симлинка и активной конфигурации

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка симлинка и активной конфигурации"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем симлинк
puts "\n🔍 Проверка симлинка..."
send "ls -la /etc/nginx/sites-enabled/ | grep estenomada\r"
expect "administrator@*"

# Проверяем, какой файл использует nginx
puts "\n🔍 Проверка активного файла конфигурации..."
send "sudo nginx -T 2>&1 | head -5\r"
expect "administrator@*"

# Проверяем, есть ли location для chef в sites-enabled
puts "\n🔍 Проверка location для chef в sites-enabled..."
send "sudo grep -n 'location.*chef' /etc/nginx/sites-enabled/estenomada 2>&1 | head -5\r"
expect "administrator@*"

# Сравниваем файлы
puts "\n🔍 Сравнение файлов..."
send "diff /etc/nginx/sites-available/estenomada /etc/nginx/sites-enabled/estenomada 2>&1 | head -10\r"
expect "administrator@*"

# Если файлы разные, копируем
puts "\n🔍 Проверка размера файлов..."
send "wc -l /etc/nginx/sites-available/estenomada /etc/nginx/sites-enabled/estenomada 2>&1\r"
expect "administrator@*"

send "exit\r"
expect eof

