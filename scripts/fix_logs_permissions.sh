#!/usr/bin/expect -f

set timeout 30
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Исправление прав на logs..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo mkdir -p /var/www/estenomada/backend/logs\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo chown -R www-data:www-data /var/www/estenomada/backend/logs\r"
expect "administrator@*"
send "sudo chmod -R 755 /var/www/estenomada/backend/logs\r"
expect "administrator@*"
send "sudo systemctl restart estenomada-backend\r"
expect "administrator@*"
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"

puts "\n✅ Права исправлены, backend перезапущен"

send "exit\r"
expect eof



