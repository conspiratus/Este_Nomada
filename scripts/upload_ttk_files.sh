#!/usr/bin/expect -f

# Загрузка файлов ТТК на сервер

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Загрузка файлов ТТК на сервер"
puts "=========================================="

# Загружаем models.py
puts "\n📤 Загрузка core/models.py..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/models.py $server:/tmp/models.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Загружаем admin.py
puts "\n📤 Загрузка core/admin.py..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/admin.py $server:/tmp/admin.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $backend_dir\r"
expect "administrator@*"

# Останавливаем Django
puts "\n🛑 Остановка Django..."
send "sudo systemctl stop estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django остановлен"
    }
}

# Копируем файлы
puts "\n📥 Копирование файлов..."
send "sudo cp /tmp/models.py core/models.py\r"
expect "administrator@*"
send "sudo cp /tmp/admin.py core/admin.py\r"
expect "administrator@*"
send "sudo chown www-data:www-data core/models.py core/admin.py\r"
expect "administrator@*"

# Проверяем, что модель есть
puts "\n🔍 Проверка модели..."
send "grep -n 'class DishTTK' core/models.py\r"
expect "administrator@*"

# Проверяем, что админка есть
puts "\n🔍 Проверка админки..."
send "grep -n 'DishTTK' core/admin.py | head -5\r"
expect "administrator@*"

# Запускаем Django
puts "\n🚀 Запуск Django..."
send "sudo systemctl start estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django запущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -15\r"
expect "administrator@*"

# Проверяем, что модель импортируется
puts "\n🔍 Проверка импорта модели..."
send "source venv/bin/activate && python manage.py shell -c \"from core.models import DishTTK; print('✅ DishTTK импортирована успешно')\"\r"
expect "administrator@*"

# Проверяем, что модель зарегистрирована в админке
puts "\n🔍 Проверка регистрации в админке..."
send "python manage.py shell -c \"from django.contrib import admin; from core.models import DishTTK; print('DishTTK registered:', DishTTK in admin.site._registry)\"\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь админку: https://estenomada.es/admin/core/dishttk/"
puts "=========================================="

