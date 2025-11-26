#!/usr/bin/expect -f

# Скрипт для деплоя изменений ТТК на продакшн
# Загружает: модели, админку, views, templates, миграции
# Применяет миграции и перезапускает сервисы

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Деплой изменений ТТК на продакшн"
puts "=========================================="

# 1. Создаем архив с изменениями
puts "\n📦 Создание архива с изменениями..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/ttk_changes.tar.gz \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='db.sqlite3' \
    --exclude='logs' \
    --exclude='staticfiles' \
    backend/core/models.py \
    backend/core/admin.py \
    backend/core/views.py \
    backend/core/urls.py \
    backend/core/templates/ \
    backend/core/migrations/0017_dishttk.py \
    backend/este_nomada/urls.py"

expect eof
puts "✅ Архив создан"

# 2. Загружаем архив на сервер
puts "\n📤 Загрузка архива на сервер..."
spawn scp /tmp/ttk_changes.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ Архив загружен"

# 3. Останавливаем сервисы
puts "\n🛑 Остановка сервисов..."
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo systemctl stop estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend остановлен"
    }
}

# 4. Распаковываем изменения
puts "\n📥 Распаковка изменений..."
send "cd $remote_backend\r"
expect "administrator@*"
send "sudo tar xzf /tmp/ttk_changes.tar.gz\r"
expect "administrator@*"
puts "✅ Изменения распакованы"

# 5. Устанавливаем права
puts "\n🔐 Установка прав доступа..."
send "sudo chown -R www-data:www-data $remote_backend/core/\r"
expect "administrator@*"
send "sudo chmod -R 755 $remote_backend/core/templates/\r"
expect "administrator@*"
puts "✅ Права установлены"

# 6. Применяем миграции
puts "\n🔄 Применение миграций..."
send "cd $remote_backend\r"
expect "administrator@*"
send "source venv/bin/activate && python manage.py migrate core\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграции применены"
    }
}

# 7. Собираем статические файлы
puts "\n📦 Сбор статических файлов..."
send "python manage.py collectstatic --noinput\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Статические файлы собраны"
    }
}

# 8. Перезапускаем сервисы
puts "\n🔄 Перезапуск сервисов..."
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

# 9. Проверяем статус
puts "\n🔍 Проверка статуса сервисов..."
send "sudo systemctl status estenomada-backend --no-pager | head -15\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Статус проверен"
    }
}

# 10. Очистка
send "rm /tmp/ttk_changes.tar.gz\r"
expect "administrator@*"

send "exit\r"
expect eof

# Очистка локального архива
spawn bash -c "rm /tmp/ttk_changes.tar.gz"
expect eof

puts "\n=========================================="
puts "✅ Деплой завершён успешно!"
puts "=========================================="
puts "Проверь админку: https://estenomada.es/admin/"
puts "Проверь интерфейс повара: https://estenomada.es/chef/"

