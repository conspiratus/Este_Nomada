#!/usr/bin/expect -f

# Исправление таблицы favorites - создание и выполнение SQL напрямую

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Создаю и выполняю SQL для исправления таблицы favorites..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 << \"PYEOF\"
import os
import sys
import django

sys.path.insert(0, \"$backend_dir\")
os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"este_nomada.settings\")
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    # Проверяем, существует ли колонка menu_item_id
    cursor.execute(\"\"\"
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = '\''favorites'\'' 
        AND COLUMN_NAME = '\''menu_item_id'\''
    \"\"\")
    col_exists = cursor.fetchone()[0]
    
    if col_exists == 0:
        print(\"🔧 Добавляю колонку menu_item_id...\")
        try:
            cursor.execute(\"\"\"
                ALTER TABLE favorites 
                ADD COLUMN menu_item_id BIGINT NOT NULL AFTER session_key
            \"\"\")
            print(\"✅ Колонка menu_item_id добавлена\")
        except Exception as e:
            print(f\"⚠️  Ошибка: {e}\")
    else:
        print(\"ℹ️  Колонка menu_item_id уже существует\")
    
    # Проверяем внешний ключ
    cursor.execute(\"\"\"
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = '\''favorites'\'' 
        AND CONSTRAINT_NAME LIKE '\''%menu_item_id%fk%'\''
    \"\"\")
    fk_exists = cursor.fetchone()[0]
    
    if fk_exists == 0:
        print(\"🔧 Добавляю внешний ключ...\")
        try:
            cursor.execute(\"\"\"
                ALTER TABLE favorites 
                ADD CONSTRAINT favorites_menu_item_id_fk 
                FOREIGN KEY (menu_item_id) 
                REFERENCES menu_items(id) 
                ON DELETE CASCADE
            \"\"\")
            print(\"✅ Внешний ключ добавлен\")
        except Exception as e:
            print(f\"⚠️  Ошибка: {e}\")
    else:
        print(\"ℹ️  Внешний ключ уже существует\")
    
    # Показываем структуру
    print(\"\\n📋 Структура таблицы favorites:\")
    cursor.execute(\"DESCRIBE favorites\")
    for row in cursor.fetchall():
        print(f\"  {row[0]:20} {row[1]:20} {row[2]:5} {row[3] or '\''\'\'':5}\")
PYEOF
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
puts "✅ Исправление завершено!"

