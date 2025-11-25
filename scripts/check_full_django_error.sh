#!/usr/bin/expect -f

# Полная проверка ошибки Django

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю полные логи ошибок Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -100 /var/www/estenomada/backend/logs/error.log 2>/dev/null | tail -50"

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

puts "🔍 Проверяю настройки БД в .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd /var/www/estenomada/backend && sudo cat .env | grep -E '^DB_|^USE_SQLITE' | head -10"

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

puts "🔍 Проверяю настройки Django settings.py..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd /var/www/estenomada/backend && sudo grep -A 10 'DATABASES' este_nomada/settings.py | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

