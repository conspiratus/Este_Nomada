#!/usr/bin/expect -f

# Исправление таблицы favorites - добавление недостающих колонок

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю структуру таблицы favorites..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py dbshell << EOF
DESCRIBE favorites;
EOF
'"

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

puts "🔧 Добавляю недостающие колонки в таблицу favorites..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py dbshell << EOF
-- Проверяем, существует ли колонка menu_item_id
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND COLUMN_NAME = '\''menu_item_id'\'');

-- Если колонки нет, добавляем её
SET @sql = IF(@col_exists = 0, 
    '\''ALTER TABLE favorites ADD COLUMN menu_item_id BIGINT NOT NULL AFTER session_key'\'', 
    '\''SELECT \"Column menu_item_id already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Проверяем, существует ли колонка customer_id
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND COLUMN_NAME = '\''customer_id'\'');

-- Если колонки нет, добавляем её
SET @sql = IF(@col_exists = 0, 
    '\''ALTER TABLE favorites ADD COLUMN customer_id BIGINT NULL AFTER id'\'', 
    '\''SELECT \"Column customer_id already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Добавляем внешние ключи, если их нет
SET @fk_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND CONSTRAINT_NAME = '\''favorites_menu_item_id_3e44dbf0_fk_menu_items_id'\'');

SET @sql = IF(@fk_exists = 0, 
    '\''ALTER TABLE favorites ADD CONSTRAINT favorites_menu_item_id_3e44dbf0_fk_menu_items_id FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE'\'', 
    '\''SELECT \"Foreign key for menu_item_id already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @fk_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND CONSTRAINT_NAME = '\''favorites_customer_id_4a609a_fk_customers_id'\'');

SET @sql = IF(@fk_exists = 0, 
    '\''ALTER TABLE favorites ADD CONSTRAINT favorites_customer_id_4a609a_fk_customers_id FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE'\'', 
    '\''SELECT \"Foreign key for customer_id already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Добавляем индексы, если их нет
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND INDEX_NAME = '\''favorites_custome_0046eb_idx'\'');

SET @sql = IF(@idx_exists = 0, 
    '\''CREATE INDEX favorites_custome_0046eb_idx ON favorites(customer_id)'\'', 
    '\''SELECT \"Index favorites_custome_0046eb_idx already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND INDEX_NAME = '\''favorites_session_bdd716_idx'\'');

SET @sql = IF(@idx_exists = 0, 
    '\''CREATE INDEX favorites_session_bdd716_idx ON favorites(session_key)'\'', 
    '\''SELECT \"Index favorites_session_bdd716_idx already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Проверяем уникальные ограничения
SET @uk_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND CONSTRAINT_TYPE = '\''UNIQUE'\''
    AND CONSTRAINT_NAME LIKE '\''%customer%menu_item%'\'');

SET @sql = IF(@uk_exists = 0, 
    '\''ALTER TABLE favorites ADD UNIQUE KEY favorites_customer_menu_item_unique (customer_id, menu_item_id)'\'', 
    '\''SELECT \"Unique constraint for customer+menu_item already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @uk_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = '\''favorites'\'' 
    AND CONSTRAINT_TYPE = '\''UNIQUE'\''
    AND CONSTRAINT_NAME LIKE '\''%session_key%menu_item%'\'');

SET @sql = IF(@uk_exists = 0, 
    '\''ALTER TABLE favorites ADD UNIQUE KEY favorites_session_menu_item_unique (session_key, menu_item_id)'\'', 
    '\''SELECT \"Unique constraint for session_key+menu_item already exists\" AS message'\'');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

EOF
'"

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

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py dbshell << EOF
DESCRIBE favorites;
EOF
'"

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

