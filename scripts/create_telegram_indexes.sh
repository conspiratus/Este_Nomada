#!/usr/bin/expect -f

# Создание индексов для telegram_admin

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set db_user "u_estenomada"
set db_password "Jovi4AndMay2020!"
set db_name "db_estenomada"

puts "🔧 Создаю индексы для telegram_admin..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"SET @exist := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'telegram_admin' AND index_name = 'telegram_ad_chat_id_idx'); SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX telegram_ad_chat_id_idx ON telegram_admin(telegram_chat_id)', 'SELECT \\\"Index already exists\\\"'); PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt; SET @exist := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'telegram_admin' AND index_name = 'telegram_ad_authoriz_idx'); SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX telegram_ad_authoriz_idx ON telegram_admin(authorized)', 'SELECT \\\"Index already exists\\\"'); PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;\" 2>&1 | grep -v Warning"

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

puts "🔍 Проверяю индексы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e 'SHOW INDEXES FROM telegram_admin;' 2>&1 | grep -v Warning"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Индексы созданы!"

