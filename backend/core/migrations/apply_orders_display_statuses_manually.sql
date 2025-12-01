-- SQL скрипт для ручного применения миграции 0048_add_orders_display_statuses
-- Применяется на сервере вручную

-- Проверяем существование колонки перед добавлением
SET @exist := (SELECT COUNT(*) FROM information_schema.columns 
               WHERE table_schema = DATABASE() 
               AND table_name = 'telegram_admin_bot_settings' 
               AND column_name = 'orders_display_statuses');

SET @sqlstmt := IF(@exist = 0, 
    'ALTER TABLE telegram_admin_bot_settings ADD COLUMN orders_display_statuses VARCHAR(255) NOT NULL DEFAULT ''pending,processing'' COMMENT ''Статусы заказов для отображения''',
    'SELECT "Column already exists"');

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

