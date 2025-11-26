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

send "sudo systemctl restart nginx\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Nginx перезапущен"
    }
}

send "sudo systemctl status nginx --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

