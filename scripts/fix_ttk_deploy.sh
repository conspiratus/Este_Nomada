#!/usr/bin/expect -f

# Исправление деплоя ТТК - применение миграции и проверка templates

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Исправление деплоя ТТК"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем наличие миграции
puts "\n🔍 Проверка миграций..."
send "cd $remote_backend && ls -la core/migrations/ | grep 0017\r"
expect "administrator@*"

# Применяем только миграцию 0017
puts "\n🔄 Применение миграции 0017_dishttk..."
send "source venv/bin/activate && python manage.py migrate core 0017\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция применена"
    }
}

# Проверяем наличие templates
puts "\n🔍 Проверка templates..."
send "ls -la core/templates/chef/ 2>/dev/null || echo 'Templates не найдены'\r"
expect "administrator@*"

# Если templates не найдены, загружаем их
send "if [ ! -d 'core/templates/chef' ]; then echo 'Загружаем templates...'; fi\r"
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

# Проверяем статус
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Исправление завершено!"
puts "=========================================="

