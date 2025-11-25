-- Миграция для поддержки многоязычности
-- Добавляет таблицы переводов и обновляет существующие таблицы

-- Таблица переводов интерфейса
CREATE TABLE IF NOT EXISTS `translations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `locale` VARCHAR(10) NOT NULL,
  `namespace` VARCHAR(100) NOT NULL,
  `key` VARCHAR(255) NOT NULL,
  `value` TEXT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_translation` (`locale`, `namespace`, `key`),
  INDEX `idx_locale` (`locale`),
  INDEX `idx_namespace` (`namespace`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица переводов меню
CREATE TABLE IF NOT EXISTS `menu_item_translations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `menu_item_id` INT NOT NULL,
  `locale` VARCHAR(10) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `category` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_menu_translation` (`menu_item_id`, `locale`),
  INDEX `idx_menu_item_id` (`menu_item_id`),
  INDEX `idx_locale` (`locale`),
  FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица переводов историй
CREATE TABLE IF NOT EXISTS `story_translations` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `story_id` INT NOT NULL,
  `locale` VARCHAR(10) NOT NULL,
  `title` VARCHAR(500) NOT NULL,
  `slug` VARCHAR(500) NOT NULL,
  `excerpt` TEXT,
  `content` LONGTEXT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_story_translation` (`story_id`, `locale`),
  INDEX `idx_story_id` (`story_id`),
  INDEX `idx_locale` (`locale`),
  INDEX `idx_slug` (`slug`),
  FOREIGN KEY (`story_id`) REFERENCES `stories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Обновляем таблицу menu_items: убираем поля name, description, category (они теперь в translations)
-- Но оставляем их для обратной совместимости, помечаем как deprecated
ALTER TABLE `menu_items` 
  MODIFY COLUMN `name` VARCHAR(255) NULL COMMENT 'Deprecated: use menu_item_translations',
  MODIFY COLUMN `description` TEXT NULL COMMENT 'Deprecated: use menu_item_translations',
  MODIFY COLUMN `category` VARCHAR(100) NULL COMMENT 'Deprecated: use menu_item_translations';

-- Обновляем таблицу stories: убираем поля title, slug, excerpt, content (они теперь в translations)
-- Но оставляем их для обратной совместимости
ALTER TABLE `stories` 
  MODIFY COLUMN `title` VARCHAR(500) NULL COMMENT 'Deprecated: use story_translations',
  MODIFY COLUMN `slug` VARCHAR(500) NULL COMMENT 'Deprecated: use story_translations',
  MODIFY COLUMN `excerpt` TEXT NULL COMMENT 'Deprecated: use story_translations',
  MODIFY COLUMN `content` LONGTEXT NULL COMMENT 'Deprecated: use story_translations';



