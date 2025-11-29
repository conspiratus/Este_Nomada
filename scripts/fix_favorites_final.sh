#!/usr/bin/expect -f

# Исправление таблицы favorites

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Исправляю таблицу favorites..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py shell'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    ">>>" {
        send "from django.db import connection\r"
        exp_continue
    }
    ">>>" {
        send "cursor = connection.cursor()\r"
        exp_continue
    }
    ">>>" {
        send "cursor.execute(\"SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'favorites' AND COLUMN_NAME = 'menu_item_id'\")\r"
        exp_continue
    }
    ">>>" {
        send "col_exists = cursor.fetchone()[0]\r"
        exp_continue
    }
    ">>>" {
        send "if col_exists == 0: cursor.execute(\"ALTER TABLE favorites ADD COLUMN menu_item_id BIGINT NOT NULL AFTER session_key\"); print('Added menu_item_id')\r"
        exp_continue
    }
    ">>>" {
        send "cursor.execute(\"ALTER TABLE favorites ADD CONSTRAINT favorites_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE\")\r"
        exp_continue
    }
    ">>>" {
        send "exit()\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts ""
puts "✅ Исправление завершено!"

