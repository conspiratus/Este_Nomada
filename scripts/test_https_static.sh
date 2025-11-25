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
send "curl -I https://estenomada.es/static/admin/css/base.css\r"
expect "administrator@*"
send "sudo nginx -t\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo systemctl status nginx --no-pager -l | head -20\r"
expect "administrator@*"
send "exit\r"
expect eof



