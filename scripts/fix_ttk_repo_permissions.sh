#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔧 Исправление прав доступа для Git репозитория..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Создаем директорию ttk с правильными правами
send "sudo mkdir -p $ttk_repo_path/ttk\r"
expect "administrator@*"

send "sudo chown -R www-data:www-data $ttk_repo_path\r"
expect "administrator@*"

send "sudo chmod -R 755 $ttk_repo_path\r"
expect "administrator@*"

puts "✅ Права доступа исправлены"

# Теперь запускаем миграцию
puts "\n🔄 Запуск миграции..."
send "cd /var/www/estenomada/backend && source venv/bin/activate && python manage.py migrate_ttk_to_git\r"
expect {
    "administrator@*" {
        puts "✅ Миграция завершена"
    }
}

send "exit\r"
expect eof

