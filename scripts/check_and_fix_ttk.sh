#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔍 Проверка и исправление..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем, есть ли файлы в /tmp
send "ls -la /tmp/views.py /tmp/models.py /tmp/ttk_view.html 2>/dev/null || echo 'Файлы не найдены'\r"
expect "administrator@*"

# Если файлы есть, перемещаем их
send "if [ -f /tmp/views.py ]; then sudo mv /tmp/views.py $remote_backend/core/views.py && sudo chown www-data:www-data $remote_backend/core/views.py && sudo chmod 644 $remote_backend/core/views.py && echo 'views.py обновлен'; fi\r"
expect "administrator@*"

send "if [ -f /tmp/models.py ]; then sudo mv /tmp/models.py $remote_backend/core/models.py && sudo chown www-data:www-data $remote_backend/core/models.py && sudo chmod 644 $remote_backend/core/models.py && echo 'models.py обновлен'; fi\r"
expect "administrator@*"

send "if [ -f /tmp/ttk_view.html ]; then sudo mv /tmp/ttk_view.html $remote_backend/core/templates/chef/ttk_view.html && sudo chown www-data:www-data $remote_backend/core/templates/chef/ttk_view.html && sudo chmod 755 $remote_backend/core/templates/chef/ttk_view.html && echo 'ttk_view.html обновлен'; fi\r"
expect "administrator@*"

# Очищаем кэш
send "find $remote_backend -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true\r"
expect "administrator@*"
send "find $remote_backend -name '*.pyc' -delete 2>/dev/null || true\r"
expect "administrator@*"

# Проверяем статус backend
send "sudo systemctl status estenomada-backend --no-pager | head -5\r"
expect "administrator@*"

# Перезапускаем если не запущен
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

send "sleep 2\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

# Проверяем, есть ли упоминания comments в views.py
send "grep -i 'comment\|TTKComment' $remote_backend/core/views.py || echo 'Нет упоминаний комментариев в views.py'\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n✅ Проверка завершена!"

