import os
import sys
import django

sys.path.insert(0, '/var/www/estenomada/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    # Проверяем тип id в menu_items
    cursor.execute("SHOW COLUMNS FROM menu_items WHERE Field = 'id'")
    menu_id_row = cursor.fetchone()
    if menu_id_row:
        menu_id_type = menu_id_row[1]
        print(f"Тип id в menu_items: {menu_id_type}")
    else:
        print("Не удалось определить тип id в menu_items")
        sys.exit(1)
    
    # Проверяем текущий тип menu_item_id
    cursor.execute("SHOW COLUMNS FROM favorites WHERE Field = 'menu_item_id'")
    fav_id_row = cursor.fetchone()
    if fav_id_row:
        fav_id_type = fav_id_row[1]
        print(f"Текущий тип menu_item_id: {fav_id_type}")
    else:
        print("Колонка menu_item_id не найдена")
        sys.exit(1)
    
    # Если типы не совпадают, изменяем
    if menu_id_type != fav_id_type:
        print(f"🔧 Изменяю тип menu_item_id с {fav_id_type} на {menu_id_type}...")
        try:
            cursor.execute(f"ALTER TABLE favorites MODIFY COLUMN menu_item_id {menu_id_type} NOT NULL")
            print("✅ Тип изменен")
        except Exception as e:
            print(f"⚠️  Ошибка при изменении типа: {e}")
    else:
        print("ℹ️  Типы уже совпадают")
    
    # Проверяем, существует ли внешний ключ
    cursor.execute("""
        SELECT COUNT(*) 
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'favorites' 
        AND CONSTRAINT_NAME LIKE '%menu_item_id%'
        AND REFERENCED_TABLE_NAME = 'menu_items'
    """)
    fk_exists = cursor.fetchone()[0]
    
    if fk_exists == 0:
        print("🔧 Добавляю внешний ключ...")
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
            # Пробуем без имени ограничения
            try:
                cursor.execute("""
                    ALTER TABLE favorites 
                    ADD FOREIGN KEY (menu_item_id) 
                    REFERENCES menu_items(id) 
                    ON DELETE CASCADE
                """)
                print("✅ Внешний ключ добавлен (без имени)")
            except Exception as e2:
                print(f"⚠️  Ошибка: {e2}")
    else:
        print("ℹ️  Внешний ключ уже существует")
    
    print("\n📋 Финальная структура таблицы favorites:")
    cursor.execute("DESCRIBE favorites")
    for row in cursor.fetchall():
        print(f"  {row[0]:20} {row[1]:30} {row[2]:5} {row[3] or '':5}")

