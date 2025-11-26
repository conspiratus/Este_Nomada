#!/usr/bin/expect -f

# Проверка таблицы django_migrations

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю таблицу django_migrations..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SELECT * FROM django_migrations LIMIT 10;' 2>&1 | head -15"

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

puts "🔍 Проверяю статус миграций Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd /var/www/estenomada/backend && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py showmigrations 2>&1 | grep -E \"\\[X\\]|\\[ \\]\" | head -20'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

