#!/usr/bin/expect -f

# Финальная загрузка миграции через /tmp

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Финальная загрузка миграции ТТК"
puts "=========================================="

# Загружаем миграцию в /tmp
puts "\n📤 Загрузка миграции в /tmp..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/migrations/0017_dishttk.py $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся к серверу
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_backend\r"
expect "administrator@*"

# Копируем миграцию с sudo
puts "\n📥 Копирование миграции..."
send "sudo cp /tmp/0017_dishttk.py core/migrations/\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция скопирована"
    }
}

send "sudo chown www-data:www-data core/migrations/0017_dishttk.py\r"
expect "administrator@*"

# Проверяем миграцию
puts "\n🔍 Проверка миграции..."
send "ls -la core/migrations/0017_dishttk.py\r"
expect "administrator@*"

# Применяем миграцию
puts "\n🔄 Применение миграции..."
send "source venv/bin/activate\r"
expect "administrator@*"
send "python manage.py migrate core\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция применена"
    }
}

# Проверяем templates
puts "\n🔍 Проверка templates..."
send "ls -la core/templates/chef/ | head -5\r"
expect "administrator@*"

# Перезапускаем сервис
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

send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Деплой завершён!"
puts "Проверь:"
puts "  - Админка: https://estenomada.es/admin/"
puts "  - Интерфейс повара: https://estenomada.es/chef/"
puts "=========================================="

