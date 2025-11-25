-- Инициализация базы данных для Este Nómada
-- Правильная структура с таблицей admins

-- Таблица администраторов (используется в коде)
CREATE TABLE IF NOT EXISTS `admins` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(255) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица историй/постов
CREATE TABLE IF NOT EXISTS `stories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(500) NOT NULL,
  `slug` VARCHAR(500) NOT NULL UNIQUE,
  `date` DATE NOT NULL,
  `excerpt` TEXT,
  `content` LONGTEXT NOT NULL,
  `cover_image` VARCHAR(500),
  `source` ENUM('manual', 'telegram') DEFAULT 'manual',
  `published` BOOLEAN DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_slug` (`slug`),
  INDEX `idx_date` (`date`),
  INDEX `idx_published` (`published`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица блюд меню
CREATE TABLE IF NOT EXISTS `menu_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `category` VARCHAR(100) NOT NULL,
  `price` DECIMAL(10, 2),
  `image` VARCHAR(500),
  `order` INT DEFAULT 0,
  `active` BOOLEAN DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_category` (`category`),
  INDEX `idx_active` (`active`),
  INDEX `idx_order` (`order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица настроек сайта
CREATE TABLE IF NOT EXISTS `settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `site_name` VARCHAR(255) NOT NULL DEFAULT 'Este Nómada',
  `site_description` TEXT,
  `contact_email` VARCHAR(255),
  `telegram_channel` VARCHAR(255),
  `bot_token` VARCHAR(255),
  `channel_id` VARCHAR(255),
  `auto_sync` BOOLEAN DEFAULT FALSE,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Вставка начальных настроек
INSERT IGNORE INTO `settings` (`site_name`, `site_description`, `contact_email`, `telegram_channel`) VALUES
('Este Nómada', 'Eastern cuisine, born on the road', 'info@estenomada.es', 'https://t.me/este_nomada');

-- Вставка начальных данных для меню (опционально)
INSERT IGNORE INTO `menu_items` (`name`, `description`, `category`, `order`) VALUES
('Плов', 'Традиционный узбекский плов с бараниной, морковью и специями', 'Плов', 1),
('Мастава', 'Густой суп с мясом, овощами и рисом, приправленный специями', 'Мастава', 2),
('Долма', 'Виноградные листья, фаршированные мясом и рисом', 'Долма', 3),
('Лагман', 'Домашняя лапша с мясом и овощами в ароматном бульоне', 'Супы', 4),
('Самса', 'Пирожки с мясом и луком, запечённые в тандыре', 'Холодные закуски', 5),
('Манты', 'Парные пельмени с мясом и луком, подаются со сметаной', 'Холодные закуски', 6),
('Шашлык', 'Мясо на углях, маринованное в специях', 'Особые блюда', 7),
('Чай', 'Традиционный восточный чай с травами', 'Напитки', 8);



