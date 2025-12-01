#!/usr/bin/expect -f

# Простой скрипт для применения миграции orders_display_statuses на сервере

set timeout 30
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"
set db_user "u_estenomada"
set db_password "Jovi4AndMay2020!"
set db_name "db_estenomada"

puts "🗄️ Применяю миграцию orders_display_statuses..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && mysql -u $db_user -p'$db_password' -h localhost $db_name < core/migrations/apply_orders_display_statuses_manually.sql 2>&1 | grep -v 'Warning'"

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

puts "🔧 Помечаю миграцию как примененную..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"INSERT IGNORE INTO django_migrations (app, name, applied) VALUES ('core', '0048_add_orders_display_statuses', NOW());\" 2>&1 | grep -v 'Warning'"

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

puts "✅ Миграция применена!"

