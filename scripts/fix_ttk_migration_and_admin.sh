#!/usr/bin/expect -f

# Проверка и исправление ТТК миграции и админки

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Проверка и исправление ТТК"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $backend_dir\r"
expect "administrator@*"

# Проверка миграций
puts "\n🔍 Проверка миграций..."
send "source venv/bin/activate && python manage.py showmigrations core | tail -5\r"
expect "administrator@*"

# Проверка регистрации DishTTK в admin.py
puts "\n🔍 Проверка регистрации DishTTK в admin.py..."
send "grep -n 'DishTTK' core/admin.py | head -10\r"
expect "administrator@*"

# Проверка таблицы в БД
puts "\n🔍 Проверка таблицы dish_ttk в БД..."
send "python manage.py shell -c \"from django.db import connection; cursor = connection.cursor(); cursor.execute('SHOW TABLES LIKE \\\"dish_ttk\\\"'); result = cursor.fetchone(); print('Table exists:', bool(result))\"\r"
expect "administrator@*"

# Применяем миграцию если нужно
puts "\n🔧 Применение миграций..."
send "python manage.py migrate core\r"
expect {
    "administrator@*" {
        puts "✅ Миграции применены"
    }
    timeout {
        puts "⚠️  Timeout"
    }
}

# Проверяем, что модель зарегистрирована
puts "\n🔍 Проверка регистрации модели..."
send "python manage.py shell -c \"from django.contrib import admin; from core.models import DishTTK; print('DishTTK registered:', DishTTK in admin.site._registry)\"\r"
expect "administrator@*"

# Перезапускаем Django
puts "\n🔄 Перезапуск Django..."
send "sudo systemctl restart estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django перезапущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

# Перезагружаем nginx
puts "\n🔄 Перезагрузка nginx..."
send "sudo systemctl reload nginx\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Nginx перезагружен"
    }
}

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь админку: https://estenomada.es/admin/core/dishttk/"
puts "=========================================="

