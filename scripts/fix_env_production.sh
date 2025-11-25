#!/usr/bin/expect -f

# Исправление .env.production

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Обновляю DB_USER и DB_NAME в .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo sed -i 's|^DB_USER=.*|DB_USER=u_estenomada|' .env.production && sudo sed -i 's|^DB_NAME=.*|DB_NAME=db_estenomada|' .env.production && echo '✅ .env.production обновлен'"

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

puts "🔍 Проверяю обновленный .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env.production | grep -E 'USE_SQLITE|DB_' | sed 's/PASSWORD=.*/PASSWORD=***/'"

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

puts "🧪 Тестирую API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/menu/?locale=en' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

