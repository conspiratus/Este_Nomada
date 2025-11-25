#!/usr/bin/expect -f

set timeout 30
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

puts "\n📊 Статус frontend:"
send "sudo systemctl status estenomada-frontend --no-pager -l | head -40\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}

puts "\n📋 Последние 50 строк логов:"
send "sudo journalctl -u estenomada-frontend --no-pager -n 50 | tail -40\r"
expect "administrator@*"

puts "\n🔍 Проверка процессов node:"
send "ps aux | grep node | grep -v grep\r"
expect "administrator@*"

puts "\n🔍 Проверка порта 3000:"
send "sudo lsof -i :3000\r"
expect "administrator@*"

send "exit\r"
expect eof


