#!/usr/bin/expect -f

# Детальная проверка логов Django

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю последние ошибки в error.log..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -50 /var/www/estenomada/backend/logs/error.log 2>/dev/null | tail -30"

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

puts "🔍 Проверяю логи Django (django.log)..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -100 /var/www/estenomada/backend/logs/django.log 2>/dev/null | tail -50"

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

puts "🔍 Проверяю journalctl с полным выводом..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 100 --no-pager | tail -80"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

