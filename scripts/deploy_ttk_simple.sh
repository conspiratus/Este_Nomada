#!/usr/bin/expect -f

# Простой деплой изменений ТТК на продакшн
# По аналогии с deploy_settings_logo.sh

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Деплой изменений ТТК на продакшн"
puts "=========================================="

# 1. Создаём архив с изменениями
puts "\n📦 Создание архива..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/ttk_backend.tar.gz \
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

# 2. Загружаем архив
puts "\n📤 Загрузка архива на сервер..."
spawn scp /tmp/ttk_backend.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ Архив загружен"

# 3. Подключаемся и распаковываем
puts "\n📥 Распаковка на сервере..."
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_backend\r"
expect "administrator@*"
send "sudo tar xzf /tmp/ttk_backend.tar.gz\r"
expect "administrator@*"
puts "✅ Файлы распакованы"

# 4. Устанавливаем права
puts "\n🔐 Установка прав..."
send "sudo chown -R www-data:www-data core/\r"
expect "administrator@*"
send "sudo chmod -R 755 core/templates/\r"
expect "administrator@*"
puts "✅ Права установлены"

# 5. Применяем миграции
puts "\n🔄 Применение миграций..."
send "source venv/bin/activate\r"
expect "administrator@*"
send "python manage.py migrate core\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграции применены"
    }
    timeout {
        puts "⚠️  Timeout (продолжаем...)"
    }
}

# 6. Собираем статику
puts "\n📦 Сбор статических файлов..."
send "python manage.py collectstatic --noinput\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Статика собрана"
    }
    timeout {
        puts "⚠️  Timeout (продолжаем...)"
    }
}

# 7. Перезапускаем сервисы
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

# 8. Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -15\r"
expect "administrator@*"

# 9. Очистка
send "rm /tmp/ttk_backend.tar.gz\r"
expect "administrator@*"

send "exit\r"
expect eof

# Очистка локально
spawn bash -c "rm /tmp/ttk_backend.tar.gz"
expect eof

puts "\n=========================================="
puts "✅ Деплой завершён!"
puts "=========================================="
puts "Проверь:"
puts "  - Админка: https://estenomada.es/admin/"
puts "  - Интерфейс повара: https://estenomada.es/chef/"
puts "=========================================="

