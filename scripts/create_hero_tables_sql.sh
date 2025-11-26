#!/usr/bin/expect -f

# Создание таблиц hero через SQL

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔧 Создаю таблицы hero через SQL..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada << 'SQL'
CREATE TABLE IF NOT EXISTS hero_settings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    slide_interval INT NOT NULL DEFAULT 5000,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT hero_settings_slide_interval_check CHECK (slide_interval >= 1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS hero_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    image_url VARCHAR(500) NOT NULL,
    \`order\` INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    CONSTRAINT hero_images_order_check CHECK (\`order\` >= 0),
    INDEX hero_images_active_2d1257_idx (active, \`order\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SQL
echo '✅ Таблицы hero созданы'"

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

puts "🔍 Проверяю созданные таблицы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SHOW TABLES LIKE \"hero%\";' 2>&1 | grep -v 'Warning'"

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

puts "🔄 Перезапускаю backend сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 5 && sudo systemctl status estenomada-backend --no-pager | head -10"

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

puts "🧪 Тестирую API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/menu/?locale=en' | head -10 && echo '' && curl -s 'https://estenomada.es/api/hero/images/' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

