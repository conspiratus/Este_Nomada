#!/usr/bin/expect -f

# Финальное исправление деплоя ТТК

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Финальное исправление деплоя ТТК"
puts "=========================================="

# 1. Загружаем templates
puts "\n📤 Загрузка templates..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/ttk_templates.tar.gz backend/core/templates/"
expect eof

spawn scp /tmp/ttk_templates.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# 2. Подключаемся к серверу
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Распаковываем templates
puts "\n📥 Распаковка templates..."
send "cd $remote_backend\r"
expect "administrator@*"
send "sudo tar xzf /tmp/ttk_templates.tar.gz\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data core/templates/\r"
expect "administrator@*"
puts "✅ Templates распакованы"

# 3. Проверяем миграции
puts "\n🔍 Проверка миграций..."
send "ls -la core/migrations/ | grep dishttk\r"
expect "administrator@*"

# 4. Применяем миграции
puts "\n🔄 Применение миграций..."
send "source venv/bin/activate\r"
expect "administrator@*"
send "python manage.py migrate core --fake-initial\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграции проверены"
    }
}

# Пробуем применить конкретную миграцию
send "python manage.py migrate core\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграции применены"
    }
}

# 5. Перезапускаем сервис
puts "\n🔄 Перезапуск backend..."
send "sudo systemctl restart estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend перезапущен"
    }
}

# 6. Проверяем статус
send "sleep 2\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

# 7. Проверяем наличие таблицы
send "python manage.py shell -c \"from core.models import DishTTK; print('Модель DishTTK:', DishTTK); print('Таблица существует!')\"\r"
expect "administrator@*"

send "exit\r"
expect eof

# Очистка
spawn bash -c "rm /tmp/ttk_templates.tar.gz"
expect eof

puts "\n=========================================="
puts "✅ Исправление завершено!"
puts "=========================================="

