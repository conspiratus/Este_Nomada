#!/usr/bin/expect -f

# Исправление USE_SQLITE на правильное булево значение

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Изменяю USE_SQLITE на 1 (для env.bool)..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo sed -i 's|^USE_SQLITE=.*|USE_SQLITE=1|' .env && sudo cat .env | grep USE_SQLITE"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 5 && sudo systemctl status estenomada-backend --no-pager | head -10"

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

puts "🧪 Тестирую API через HTTPS..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST https://estenomada.es/api/auth/login/ -H 'Content-Type: application/json' -d '{\"username\":\"test\",\"password\":\"test\"}' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

