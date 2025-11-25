#!/usr/bin/expect -f

# Проверка логов фронтенда

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка логов фронтенда"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo journalctl -u estenomada-frontend -n 50 --no-pager\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Логи показаны"
    }
}

send "exit\r"
expect eof

