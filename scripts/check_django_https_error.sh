#!/usr/bin/expect -f

# Проверка ошибок Django при запросах через HTTPS

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю последние ошибки в логах Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -50 /var/www/estenomada/backend/logs/error.log 2>/dev/null | grep -A 10 -i 'error\|exception\|traceback' | tail -30"

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

puts "🔍 Проверяю логи доступа Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -20 /var/www/estenomada/backend/logs/access.log 2>/dev/null"

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

puts "🔍 Проверяю journalctl логи..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 50 --no-pager | grep -A 15 -i 'error\|exception\|traceback' | tail -40"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

