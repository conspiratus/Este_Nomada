#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔍 Проверка миграций на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_backend\r"
expect "administrator@*"
send "ls -la core/migrations/0018*\r"
expect "administrator@*"

send "source venv/bin/activate\r"
expect "administrator@*"
send "python manage.py showmigrations core | grep 0018\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Проверка завершена"
    }
}

send "exit\r"
expect eof

