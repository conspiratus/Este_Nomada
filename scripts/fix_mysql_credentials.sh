#!/usr/bin/expect -f

# Исправление учетных данных MySQL

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Обновляю учетные данные MySQL..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'sed -i \"s|^DB_USER=.*|DB_USER=u_estenomada|\" .env && sed -i \"s|^DB_NAME=.*|DB_NAME=db_estenomada|\" .env && echo \"✅ Учетные данные обновлены\"'"

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

puts "🔍 Проверяю обновленный .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env | grep -E 'USE_SQLITE|DB_' | sed 's/PASSWORD=.*/PASSWORD=***/'"

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

puts "🧪 Тестирую подключение к MySQL с новыми учетными данными..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SELECT 1' 2>&1 | head -5"

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

