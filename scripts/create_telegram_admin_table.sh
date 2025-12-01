#!/usr/bin/expect -f

# Создание таблицы telegram_admin с правильным типом user_id

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set db_user "u_estenomada"
set db_password "Jovi4AndMay2020!"
set db_name "db_estenomada"

puts "🔧 Создаю таблицу telegram_admin..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"CREATE TABLE IF NOT EXISTS telegram_admin (id BIGINT AUTO_INCREMENT PRIMARY KEY, telegram_chat_id BIGINT NOT NULL UNIQUE, authorized BOOLEAN NOT NULL DEFAULT FALSE, username VARCHAR(255), first_name VARCHAR(255), last_name VARCHAR(255), created_at DATETIME(6) NOT NULL, updated_at DATETIME(6) NOT NULL, user_id INT NOT NULL UNIQUE, CONSTRAINT telegram_admin_user_id_fk FOREIGN KEY (user_id) REFERENCES auth_user(id) ON DELETE CASCADE) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\" 2>&1 | grep -v Warning"

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

puts "🔧 Создаю индексы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e \"CREATE INDEX IF NOT EXISTS telegram_ad_chat_id_idx ON telegram_admin(telegram_chat_id); CREATE INDEX IF NOT EXISTS telegram_ad_authoriz_idx ON telegram_admin(authorized);\" 2>&1 | grep -v Warning"

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

puts "🔍 Проверяю созданные таблицы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u $db_user -p'$db_password' -h localhost $db_name -e 'SHOW TABLES LIKE \"telegram%\"; DESCRIBE telegram_admin;' 2>&1 | grep -v Warning"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Таблица создана!"

