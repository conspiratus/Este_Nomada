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
send "ls -la /var/www/estenomada/backend/staticfiles/admin/css/ | head -15\r"
expect "administrator@*"
send "ls -la /var/www/estenomada/backend/staticfiles/\r"
expect "administrator@*"
send "cat /etc/nginx/sites-available/estenomada.production.conf | grep -A5 'location /static/'\r"
expect "administrator@*"
send "exit\r"
expect eof


