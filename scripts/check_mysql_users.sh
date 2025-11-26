#!/usr/bin/expect -f

# Проверка пользователей MySQL

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю доступные пользователи MySQL..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo mysql -e \"SELECT User, Host FROM mysql.user WHERE User LIKE '%estenomada%' OR User LIKE '%czjey8yl0%';\" 2>&1"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "🔍 Проверяю, какие базы данных доступны..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo mysql -e \"SHOW DATABASES;\" 2>&1 | grep -i estenomada"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

