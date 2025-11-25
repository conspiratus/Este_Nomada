#!/usr/bin/expect -f

# Проверка развертывания функционала ТТК

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка развертывания функционала ТТК"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем модели
puts "\n🔍 Проверка моделей..."
send "cd /var/www/estenomada/backend && source venv/bin/activate && python manage.py showmigrations core | grep -E '(0018|ttk)'\r"
expect "administrator@*"

# Проверяем наличие таблиц в БД
puts "\n🔍 Проверка таблиц в БД..."
send "python manage.py dbshell -c \"SHOW TABLES LIKE 'ttk%';\" 2>&1 | grep -v 'mysql>' | grep -v 'Reading table' | grep -v '^$'\r"
expect "administrator@*"

# Проверяем файлы
puts "\n🔍 Проверка файлов..."
send "ls -la /var/www/estenomada/backend/core/forms.py /var/www/estenomada/backend/core/templates/chef/ttk_view.html 2>&1\r"
expect "administrator@*"

# Проверяем views.py на наличие новых функций
puts "\n🔍 Проверка views.py..."
send "grep -c 'chef_ttk_comment' /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"
send "grep -c 'TTKComment' /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"

# Проверяем urls.py
puts "\n🔍 Проверка urls.py..."
send "grep -c 'ttk_comment' /var/www/estenomada/backend/core/urls.py\r"
expect "administrator@*"

# Проверяем статус Django
puts "\n🔍 Проверка статуса Django..."
send "sudo systemctl status estenomada-backend --no-pager | head -5\r"
expect "administrator@*"

# Проверяем логи на ошибки
puts "\n🔍 Проверка последних ошибок в логах..."
send "sudo tail -20 /var/www/estenomada/backend/logs/error.log | grep -i error | tail -5\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Проверка завершена"
puts "=========================================="

