#!/usr/bin/expect -f

# Прямое применение SQL для добавления колонки orders_display_statuses

set timeout 30
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set db_user "u_estenomada"
set db_password "Jovi4AndMay2020!"
set db_name "db_estenomada"

puts "🗄️ Применяю SQL для добавления колонки orders_display_statuses..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"SET @exist := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'telegram_admin_bot_settings' AND column_name = 'orders_display_statuses'); SET @sqlstmt := IF(@exist = 0, 'ALTER TABLE telegram_admin_bot_settings ADD COLUMN orders_display_statuses VARCHAR(255) NOT NULL DEFAULT \\'pending,processing\\' COMMENT \\'Статусы заказов для отображения\\'', 'SELECT \\\"Column already exists\\\"'); PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;\" 2>&1 | grep -v 'Warning'"

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

spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"INSERT IGNORE INTO django_migrations (app, name, applied) VALUES ('core', '0048_add_orders_display_statuses', NOW());\" 2>&1 | grep -v 'Warning'"

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

