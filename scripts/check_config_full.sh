#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

send "sudo wc -l /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "sudo grep -n 'location /api/' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "sudo grep -n 'location.*chef' /etc/nginx/sites-available/estenomada | head -5\r"
expect "administrator@*"

send "sudo sed -n '50,150p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "exit\r"
expect eof

