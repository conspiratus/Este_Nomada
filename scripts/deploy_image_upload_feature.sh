#!/usr/bin/expect -f

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Развертывание функции загрузки изображений"
puts "=========================================="

# Загружаем обновленные файлы
puts "\n📤 Загрузка файлов..."
spawn scp backend/core/models.py $server:/tmp/models.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp backend/core/admin.py $server:/tmp/admin.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp backend/api/serializers.py $server:/tmp/serializers.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp backend/core/migrations/0007_menuitemimage_image_alter_menuitemimage_image_url.py $server:/tmp/0007_migration.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ Файлы загружены"

# Подключаемся к серверу
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Копируем файлы
puts "\n📋 Копирование файлов..."
send "sudo cp /tmp/models.py /var/www/estenomada/backend/core/\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo cp /tmp/admin.py /var/www/estenomada/backend/core/\r"
expect "administrator@*"
send "sudo cp /tmp/serializers.py /var/www/estenomada/backend/api/\r"
expect "administrator@*"
send "sudo cp /tmp/0007_migration.py /var/www/estenomada/backend/core/migrations/0007_menuitemimage_image_alter_menuitemimage_image_url.py\r"
expect "administrator@*"
puts "✅ Файлы скопированы"

# Устанавливаем права
send "sudo chown -R www-data:www-data /var/www/estenomada/backend/core/\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data /var/www/estenomada/backend/api/\r"
expect "administrator@*"

# Создаем директорию media
puts "\n📁 Создание директории media..."
send "sudo mkdir -p /var/www/estenomada/backend/media/menu_items\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data /var/www/estenomada/backend/media\r"
expect "administrator@*"
send "sudo chmod -R 755 /var/www/estenomada/backend/media\r"
expect "administrator@*"
puts "✅ Директория media создана"

# Применяем миграции
puts "\n🔄 Применение миграций..."
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"
send "sudo -u www-data venv/bin/python3 manage.py migrate\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграции применены"
    }
    timeout {
        puts "⚠️  Timeout при миграции"
    }
}

# Перезапускаем backend
puts "\n🔄 Перезапуск Django backend..."
send "sudo systemctl restart estenomada-backend\r"
expect "administrator@*"
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"

puts "\n=========================================="
puts "✅ ГОТОВО!"
puts "=========================================="
puts "Теперь можешь загружать изображения в админке!"
puts "В форме блюда будет поле 'Изображение' для загрузки."
puts "=========================================="

send "exit\r"
expect eof


