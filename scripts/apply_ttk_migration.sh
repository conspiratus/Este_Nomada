#!/usr/bin/expect -f

# Применение миграции ТТК с исправлением проблем

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Применение миграции ТТК"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_backend\r"
expect "administrator@*"
send "source venv/bin/activate\r"
expect "administrator@*"

# Помечаем миграцию 0016 как применённую
puts "\n🔧 Помечаем миграцию 0016 как применённую..."
send "python manage.py migrate core 0016 --fake\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция 0016 помечена"
    }
}

# Применяем миграцию 0017
puts "\n🔄 Применение миграции 0017 (DishTTK)..."
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

# Проверяем наличие таблицы
puts "\n🔍 Проверка таблицы dish_ttk..."
send "python manage.py shell -c \"from django.db import connection; cursor = connection.cursor(); cursor.execute('SHOW TABLES LIKE \\\\'dish_ttk\\\\''); print('Таблица существует!' if cursor.fetchone() else 'Таблица не найдена!')\"\r"
expect "administrator@*"

# Проверяем templates
puts "\n🔍 Проверка templates..."
send "ls -la core/templates/chef/ 2>/dev/null | head -5 || echo 'Templates не найдены'\r"
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
puts "✅ Готово! Проверь:"
puts "  - Админка: https://estenomada.es/admin/"
puts "  - Интерфейс повара: https://estenomada.es/chef/"
puts "=========================================="

