#!/usr/bin/expect -f

# Применение миграций Telegram бота на сервере

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"
set db_user "u_estenomada"
set db_password "Jovi4AndMay2020!"
set db_name "db_estenomada"

puts "🔍 Проверяю текущий статус миграций..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py showmigrations core 2>&1 | grep 004'"

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

puts "🗄️ Применяю SQL скрипт для создания таблиц..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && mysql -u $db_user -p'$db_password' -h localhost $db_name < core/migrations/apply_telegram_bot_manually.sql 2>&1 | grep -v 'Warning'"

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

puts "🔍 Проверяю, создались ли таблицы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e 'SHOW TABLES LIKE \"telegram%\";' 2>&1 | grep -v 'Warning'"

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

puts "🔧 Помечаю миграции как примененные..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"INSERT IGNORE INTO django_migrations (app, name, applied) VALUES ('core', '0045_add_telegram_admin_bot', NOW()), ('core', '0047_merge_telegram_and_ttk', NOW()), ('core', '0046_add_telegram_admin_bot', NOW());\" 2>&1 | grep -v 'Warning'"

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

puts "🔍 Проверяю статус миграций после применения..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py showmigrations core 2>&1 | grep 004'"

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

puts "✅ Миграции применены!"

