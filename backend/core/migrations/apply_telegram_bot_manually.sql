-- SQL скрипт для ручного применения миграции Telegram бота
-- Используйте этот скрипт, если миграции не применяются автоматически из-за конфликтов

-- 1. Создаем таблицу telegram_admin_bot_settings (если не существует)
CREATE TABLE IF NOT EXISTS telegram_admin_bot_settings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    bot_token LONGTEXT,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    notify_new_order BOOLEAN NOT NULL DEFAULT TRUE,
    notify_order_status_change BOOLEAN NOT NULL DEFAULT TRUE,
    notify_new_customer BOOLEAN NOT NULL DEFAULT TRUE,
    notify_review BOOLEAN NOT NULL DEFAULT TRUE,
    daily_reports_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    daily_reports_time TIME NOT NULL DEFAULT '09:00:00',
    menu_item_low_stock_threshold INT NOT NULL DEFAULT 5,
    ingredient_threshold_kg DECIMAL(10,3) NOT NULL DEFAULT 1.0,
    ingredient_threshold_g DECIMAL(10,3) NOT NULL DEFAULT 500.0,
    ingredient_threshold_l DECIMAL(10,3) NOT NULL DEFAULT 1.0,
    ingredient_threshold_ml DECIMAL(10,3) NOT NULL DEFAULT 500.0,
    ingredient_threshold_pcs DECIMAL(10,3) NOT NULL DEFAULT 10.0,
    updated_at DATETIME(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Создаем таблицу telegram_admin (если не существует)
-- Используем INT для user_id, так как auth_user.id обычно INT
CREATE TABLE IF NOT EXISTS telegram_admin (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    telegram_chat_id BIGINT NOT NULL UNIQUE,
    authorized BOOLEAN NOT NULL DEFAULT FALSE,
    username VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    user_id INT NOT NULL UNIQUE,
    CONSTRAINT telegram_admin_user_id_fk FOREIGN KEY (user_id) REFERENCES auth_user(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Создаем индексы (если не существуют)
CREATE INDEX IF NOT EXISTS telegram_ad_chat_id_idx ON telegram_admin(telegram_chat_id);
CREATE INDEX IF NOT EXISTS telegram_ad_authoriz_idx ON telegram_admin(authorized);

-- 4. Помечаем миграции как примененные в django_migrations
-- ВАЖНО: Замените '0046_add_telegram_admin_bot' на фактическое имя миграции, если оно отличается
INSERT IGNORE INTO django_migrations (app, name, applied) 
VALUES ('core', '0046_add_telegram_admin_bot', NOW());

-- Если на сервере есть старая миграция 0045_add_telegram_admin_bot, также пометьте её как примененную
INSERT IGNORE INTO django_migrations (app, name, applied) 
VALUES ('core', '0045_add_telegram_admin_bot', NOW());

-- Если есть merge миграция 0047, также пометьте её
INSERT IGNORE INTO django_migrations (app, name, applied) 
VALUES ('core', '0047_merge_telegram_and_ttk', NOW());

