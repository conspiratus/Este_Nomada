#!/usr/bin/expect -f

# Простое исправление таблицы favorites - добавление недостающей колонки menu_item_id

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю структуру таблицы favorites..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py dbshell -c \"DESCRIBE favorites;\"'"

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

puts "🔧 Добавляю недостающую колонку menu_item_id..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo mysql -u www-data -p'Jovi4AndMay2020!' db_estenomada -e \"ALTER TABLE favorites ADD COLUMN menu_item_id BIGINT NOT NULL AFTER session_key;\""

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

puts "🔧 Добавляю внешний ключ для menu_item_id..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo mysql -u www-data -p'Jovi4AndMay2020!' db_estenomada -e \"ALTER TABLE favorites ADD CONSTRAINT favorites_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE;\""

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

puts "🔧 Добавляю уникальное ограничение для session_key + menu_item_id..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo mysql -u www-data -p'Jovi4AndMay2020!' db_estenomada -e \"ALTER TABLE favorites ADD UNIQUE KEY favorites_session_menu_item_unique (session_key, menu_item_id);\""

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

puts "📋 Проверяю структуру таблицы после исправления..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py dbshell -c \"DESCRIBE favorites;\"'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts ""
puts "✅ Исправление таблицы favorites завершено!"

