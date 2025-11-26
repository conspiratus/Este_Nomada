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
send "curl -I http://localhost/static/admin/css/base.css\r"
expect "administrator@*"
send "cat /etc/nginx/sites-enabled/estenomada.production.conf | grep -B2 -A8 'location /static/'\r"
expect "administrator@*"
send "ls -la /etc/nginx/sites-enabled/\r"
expect "administrator@*"
send "exit\r"
expect eof



