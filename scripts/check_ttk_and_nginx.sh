#!/usr/bin/expect -f

# Проверка ТТК, миграции и nginx

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"
set backend_dir "/var/www/estenomada-backend"

puts "=========================================="
puts "Проверка ТТК, миграции и nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверка миграций
puts "\n🔍 Проверка миграций..."
send "cd $backend_dir\r"
expect "administrator@*"
send "source venv/bin/activate && python manage.py showmigrations core | grep -E '(0017|\[X\]|\[ \])'\r"
expect "administrator@*"

# Проверка модели в админке
puts "\n🔍 Проверка регистрации DishTTK в admin.py..."
send "grep -n 'DishTTK' core/admin.py | head -5\r"
expect "administrator@*"

# Проверка таблицы в БД
puts "\n🔍 Проверка таблицы dish_ttk в БД..."
send "python manage.py shell -c \"from django.db import connection; cursor = connection.cursor(); cursor.execute('SHOW TABLES LIKE \\\"dish_ttk\\\"'); print('Table exists:', bool(cursor.fetchone()))\"\r"
expect "administrator@*"

# Проверка статуса Django
puts "\n🔍 Проверка статуса Django..."
send "sudo systemctl status estenomada-backend --no-pager | head -15\r"
expect "administrator@*"

# Проверка nginx
puts "\n🔍 Проверка nginx..."
send "sudo nginx -t\r"
expect "administrator@*"
send "sudo systemctl status nginx --no-pager | head -15\r"
expect "administrator@*"

# Проверка логов Django
puts "\n🔍 Последние логи Django..."
send "sudo journalctl -u estenomada-backend -n 30 --no-pager | grep -i -E '(error|ttk|dish)' | tail -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Проверка завершена"
puts "=========================================="

