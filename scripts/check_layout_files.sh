#!/usr/bin/expect -f

# Проверка layout файлов на сервере

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Проверка layout файлов на сервере"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_dir\r"
expect "administrator@*"

puts "\n🔍 Проверка app/layout.tsx..."
send "grep -A 3 'return' app/layout.tsx\r"
expect "administrator@*"

puts "\n🔍 Проверка locale layout (html тег)..."
send "grep '<html' 'app/[locale]/layout.tsx' | head -1\r"
expect "administrator@*"

puts "\n🔍 Проверка locale layout (body тег)..."
send "grep '<body' 'app/[locale]/layout.tsx' | head -1\r"
expect "administrator@*"

send "exit\r"
expect eof

