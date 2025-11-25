#!/usr/bin/expect -f

# Проверка и исправление настроек БД Django

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю текущий .env файл..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env 2>/dev/null | head -20"

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

puts "🔧 Устанавливаю USE_SQLITE=True для использования SQLite..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'if grep -q \"^USE_SQLITE\" .env 2>/dev/null; then sed -i \"s|^USE_SQLITE=.*|USE_SQLITE=True|\" .env; else echo \"USE_SQLITE=True\" >> .env; fi && echo \"✅ USE_SQLITE установлен\"'"

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

puts "🔄 Перезапускаю backend сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 3 && sudo systemctl status estenomada-backend --no-pager | head -15"

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

puts "🧪 Тестирую API логин..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST http://localhost:8000/api/auth/login/ -H 'Content-Type: application/json' -d '{\"username\":\"test\",\"password\":\"test\"}' | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

