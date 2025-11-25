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
send "sudo systemctl status estenomada-backend --no-pager -l | head -30\r"
expect "administrator@*"
send "sudo journalctl -u estenomada-backend --no-pager -n 20\r"
expect "administrator@*"
send "exit\r"
expect eof



