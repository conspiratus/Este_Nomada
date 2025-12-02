-- SQL скрипт для ручного применения миграции 0049_add_banned_to_telegram_admin
-- Применяется на сервере вручную

-- 1. Добавляем поле banned
SET @exist := (SELECT COUNT(*) FROM information_schema.columns 
               WHERE table_schema = DATABASE() 
               AND table_name = 'telegram_admin' 
               AND column_name = 'banned');

SET @sqlstmt := IF(@exist = 0, 
    'ALTER TABLE telegram_admin ADD COLUMN banned BOOLEAN NOT NULL DEFAULT FALSE COMMENT ''Если включено, бот не будет отправлять этому пользователю никакие сообщения''',
    'SELECT "Column already exists"');

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Делаем поле user_id nullable (если еще не nullable)
SET @exist_nullable := (SELECT COUNT(*) FROM information_schema.columns 
                        WHERE table_schema = DATABASE() 
                        AND table_name = 'telegram_admin' 
                        AND column_name = 'user_id'
                        AND is_nullable = 'YES');

SET @sqlstmt2 := IF(@exist_nullable = 0,
    'ALTER TABLE telegram_admin MODIFY COLUMN user_id INT NULL',
    'SELECT "Column already nullable"');

PREPARE stmt2 FROM @sqlstmt2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

