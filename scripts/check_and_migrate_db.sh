#!/usr/bin/expect -f

# Проверка и применение миграций

set timeout 120
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю таблицы в базе данных..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SHOW TABLES;' 2>&1 | head -20"

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

puts "🔍 Проверяю примененные миграции Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py showmigrations 2>&1 | head -30'"

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

puts "🔧 Применяю миграции..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py migrate --noinput 2>&1'"

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

