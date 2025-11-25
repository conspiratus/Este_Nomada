#!/usr/bin/expect -f

# Помечаем миграцию 0017 как применённую (таблица уже существует)

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Помечаем миграцию 0017 как применённую"
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

puts "\n🔧 Помечаем миграцию как применённую..."
send "python manage.py migrate core 0017 --fake\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция помечена"
    }
}

puts "\n🔍 Проверяем, что всё работает..."
send "python manage.py shell -c \"from core.models import DishTTK; print('✅ Модель DishTTK доступна!')\"\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово! Всё должно работать!"
puts "=========================================="

