#!/usr/bin/env python3
"""
Скрипт для исправления таблицы favorites - добавление недостающей колонки menu_item_id.
Запускать на сервере: python3 fix_favorites.py
"""
import os
import sys
import django

# Настройка Django
sys.path.insert(0, '/var/www/estenomada/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from django.db import connection

def fix_favorites_table():
    """Исправляет структуру таблицы favorites."""
    with connection.cursor() as cursor:
        # Проверяем, существует ли колонка menu_item_id
        cursor.execute("""
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'favorites' 
            AND COLUMN_NAME = 'menu_item_id'
        """)
        col_exists = cursor.fetchone()[0]
        
        if col_exists == 0:
            print("🔧 Добавляю колонку menu_item_id...")
            try:
                cursor.execute("""
                    ALTER TABLE favorites 
                    ADD COLUMN menu_item_id BIGINT NOT NULL AFTER session_key
                """)
                print("✅ Колонка menu_item_id добавлена")
            except Exception as e:
                print(f"⚠️  Ошибка при добавлении колонки: {e}")
        else:
            print("ℹ️  Колонка menu_item_id уже существует")
        
        # Проверяем, существует ли внешний ключ
        cursor.execute("""
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'favorites' 
            AND CONSTRAINT_NAME LIKE '%menu_item_id%'
            AND CONSTRAINT_NAME LIKE '%fk%'
        """)
        fk_exists = cursor.fetchone()[0]
        
        if fk_exists == 0:
            print("🔧 Добавляю внешний ключ для menu_item_id...")
            try:
                cursor.execute("""
                    ALTER TABLE favorites 
                    ADD CONSTRAINT favorites_menu_item_id_fk 
                    FOREIGN KEY (menu_item_id) 
                    REFERENCES menu_items(id) 
                    ON DELETE CASCADE
                """)
                print("✅ Внешний ключ добавлен")
            except Exception as e:
                print(f"⚠️  Ошибка при добавлении внешнего ключа: {e}")
        else:
            print("ℹ️  Внешний ключ уже существует")
        
        # Проверяем уникальное ограничение для session_key + menu_item_id
        cursor.execute("""
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'favorites' 
            AND CONSTRAINT_TYPE = 'UNIQUE'
            AND CONSTRAINT_NAME LIKE '%session%menu_item%'
        """)
        uk_exists = cursor.fetchone()[0]
        
        if uk_exists == 0:
            print("🔧 Добавляю уникальное ограничение для session_key + menu_item_id...")
            try:
                cursor.execute("""
                    ALTER TABLE favorites 
                    ADD UNIQUE KEY favorites_session_menu_item_unique 
                    (session_key, menu_item_id)
                """)
                print("✅ Уникальное ограничение добавлено")
            except Exception as e:
                print(f"⚠️  Ошибка при добавлении уникального ограничения: {e}")
        else:
            print("ℹ️  Уникальное ограничение уже существует")
        
        # Показываем финальную структуру таблицы
        print("\n📋 Текущая структура таблицы favorites:")
        cursor.execute("DESCRIBE favorites")
        for row in cursor.fetchall():
            print(f"  {row[0]:20} {row[1]:20} {row[2]:5} {row[3]:5} {row[4] or 'NULL':10}")

if __name__ == '__main__':
    fix_favorites_table()

