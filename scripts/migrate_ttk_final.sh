#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔄 Финальная миграция ТТК файлов в Git..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Запускаем миграцию от имени www-data
puts "\n🔄 Запуск миграции от имени www-data..."
send "cd $remote_backend && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py migrate_ttk_to_git'\r"
expect {
    "administrator@*" {
        puts "✅ Миграция завершена"
    }
}

# Проверяем результат
send "cd /var/www/estenomada/ttk_repo && sudo -u www-data git log --oneline -5\r"
expect "administrator@*"

send "cd /var/www/estenomada/ttk_repo && sudo -u www-data ls -la ttk/ 2>/dev/null || echo 'Директория ttk пуста'\r"
expect "administrator@*"

send "exit\r"
expect eof

