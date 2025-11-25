#!/usr/bin/expect -f

# Создание таблицы dish_ttk вручную через SQL

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Создание таблицы dish_ttk вручную"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_backend\r"
expect "administrator@*"
send "source venv/bin/activate\r"
expect "administrator@*"

# Создаём таблицу через SQL
puts "\n🔧 Создание таблицы через SQL..."
send "python manage.py dbshell << 'EOF'\r"
expect "administrator@*"
send "CREATE TABLE IF NOT EXISTS dish_ttk (\r"
expect "administrator@*"
send "    id BIGINT AUTO_INCREMENT PRIMARY KEY,\r"
expect "administrator@*"
send "    menu_item_id BIGINT NOT NULL UNIQUE,\r"
expect "administrator@*"
send "    ttk_file VARCHAR(100) NOT NULL,\r"
expect "administrator@*"
send "    version VARCHAR(50) NULL,\r"
expect "administrator@*"
send "    notes LONGTEXT NULL,\r"
expect "administrator@*"
send "    active BOOLEAN NOT NULL DEFAULT 1,\r"
expect "administrator@*"
send "    created_at DATETIME(6) NOT NULL,\r"
expect "administrator@*"
send "    updated_at DATETIME(6) NOT NULL,\r"
expect "administrator@*"
send "    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE,\r"
expect "administrator@*"
send "    INDEX idx_menu_item (menu_item_id),\r"
expect "administrator@*"
send "    INDEX idx_active (active)\r"
expect "administrator@*"
send ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\r"
expect "administrator@*"
send "EOF\r"
expect "administrator@*"

# Помечаем миграцию как применённую
puts "\n🔧 Помечаем миграцию как применённую..."
send "python manage.py migrate core 0017 --fake\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция помечена"
    }
}

# Перезапускаем сервис
puts "\n🔄 Перезапуск backend..."
send "sudo systemctl restart estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend перезапущен"
    }
}

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "=========================================="

