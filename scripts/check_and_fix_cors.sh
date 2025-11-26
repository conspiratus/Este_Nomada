#!/usr/bin/expect -f

# Проверка и исправление CORS настроек

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю CORS настройки в .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env.production | grep -E 'CORS_ALLOWED_ORIGINS'"

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

puts "🔧 Обновляю CORS настройки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo sed -i 's|^CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://estenomada.es,https://www.estenomada.es,http://localhost:3000|' .env.production && echo '✅ CORS обновлен'"

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

puts "🔍 Проверяю обновленные настройки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env.production | grep -E 'CORS_ALLOWED_ORIGINS'"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 3 && sudo systemctl status estenomada-backend --no-pager | head -10"

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

puts "🧪 Тестирую логин через curl..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST 'https://estenomada.es/api/auth/login/' -H 'Content-Type: application/json' -H 'Origin: https://estenomada.es' -d '{\"username\":\"admin\",\"password\":\"admin123\"}' | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

