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

puts "\n📊 Статус сервисов:"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"

puts "\n📋 Логи backend (последние 30 строк):"
send "sudo journalctl -u estenomada-backend --no-pager -n 30\r"
expect "administrator@*"

puts "\n📋 Логи frontend (последние 30 строк):"
send "sudo journalctl -u estenomada-frontend --no-pager -n 30\r"
expect "administrator@*"

puts "\n🔍 Проверка главной страницы:"
send "curl -I https://estenomada.es/ 2>&1 | head -5\r"
expect "administrator@*"

send "exit\r"
expect eof


