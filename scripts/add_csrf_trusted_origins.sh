#!/usr/bin/expect -f

# Добавление CSRF_TRUSTED_ORIGINS в settings.py

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю текущие настройки CSRF..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo grep -i 'CSRF' este_nomada/settings.py | head -5"

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

puts "🔍 Проверяю детальные логи ошибок Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -100 /var/www/estenomada/backend/logs/django.log 2>/dev/null | grep -A 20 -i 'error\|exception\|traceback' | tail -50"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

