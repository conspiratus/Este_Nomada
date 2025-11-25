#!/usr/bin/expect -f

# Проверка server блоков в конфигурации

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка server блоков"
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

# Проверяем, в каком server блоке находятся location для chef
puts "\n🔍 Проверка server блоков с location для chef..."
send "sudo awk '/server {/,/^}/ {if (/location.*chef/) {print \"Found in server block starting at line\", start; print NR\": \"\$0}} {if (/^server {/) start=NR}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Читаем конфигурацию вокруг location для chef
puts "\n🔍 Чтение конфигурации вокруг location для chef..."
send "sudo sed -n '30,200p' /etc/nginx/sites-available/estenomada | grep -B 10 -A 5 'location.*chef' | head -30\r"
expect "administrator@*"

# Проверяем, есть ли listen 443 в блоке с location для chef
puts "\n🔍 Проверка listen директив..."
send "sudo awk '/location.*chef/,/^}/ {if (/listen/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем весь server блок, где находится location для chef
puts "\n🔍 Проверка server блока с location для chef..."
send "sudo awk '/location.*chef/ {found=1; block_start=NR-50} found && /^server {/ {block_start=NR} found && /^}/ && NR > block_start {print \"Server block ends at line\", NR; exit} END {if (found) print \"Location for chef found, checking context...\"}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Читаем строки 30-200 для понимания структуры
puts "\n🔍 Чтение структуры (строки 30-200)..."
send "sudo sed -n '30,200p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "exit\r"
expect eof

