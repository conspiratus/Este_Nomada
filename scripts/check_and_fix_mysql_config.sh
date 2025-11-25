#!/usr/bin/expect -f

# Проверка и исправление настроек MySQL

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю текущий .env файл..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env"

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

puts "🔧 Устанавливаю USE_SQLITE=False..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'if grep -q \"^USE_SQLITE\" .env 2>/dev/null; then sed -i \"s|^USE_SQLITE=.*|USE_SQLITE=False|\" .env; else echo \"USE_SQLITE=False\" >> .env; fi && echo \"✅ USE_SQLITE установлен\"'"

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

puts "🔍 Проверяю настройки MySQL в .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo grep -E '^DB_' .env || echo 'Настройки MySQL не найдены'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

