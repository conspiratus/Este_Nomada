#!/usr/bin/expect -f

# Проверка таблиц и применение миграций

set timeout 120
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю таблицы в базе данных..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SHOW TABLES;' 2>&1 | grep -v 'Warning'"

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

puts "🔍 Проверяю, есть ли таблица menu_item_images..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SHOW TABLES LIKE \"%menu%\" OR SHOW TABLES LIKE \"%image%\";' 2>&1 | grep -v 'Warning'"

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

puts "🔧 Применяю все миграции (включая fake для существующих)..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py migrate --run-syncdb 2>&1 | tail -30'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

