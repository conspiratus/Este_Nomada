#!/usr/bin/expect -f

# Проверка, что миграция помечена как примененная

set timeout 30
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set db_user "u_estenomada"
set db_password "Jovi4AndMay2020!"
set db_name "db_estenomada"

puts "🔍 Проверяю статус миграции 0048_add_orders_display_statuses..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"SELECT * FROM django_migrations WHERE app = 'core' AND name = '0048_add_orders_display_statuses';\" 2>&1 | grep -v 'Warning'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 1

puts "✅ Проверка завершена!"

