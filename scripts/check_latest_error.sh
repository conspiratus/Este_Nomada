#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔍 Проверка последних ошибок..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo tail -100 $remote_backend/logs/error.log | tail -50\r"
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
