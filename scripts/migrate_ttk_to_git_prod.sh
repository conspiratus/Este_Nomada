#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔄 Миграция ТТК файлов в Git..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Сначала проверяем dry-run
puts "\n🔍 Проверка миграции (dry-run)..."
send "cd $remote_backend && source venv/bin/activate && python manage.py migrate_ttk_to_git --dry-run\r"
expect {
    "administrator@*" {
        puts "✅ Dry-run завершен"
    }
}

puts "\n❓ Запустить реальную миграцию? (y/n)"
puts "   Это перенесет все существующие ТТК файлы в Git репозиторий"

send "cd $remote_backend && source venv/bin/activate && python manage.py migrate_ttk_to_git\r"
expect {
    "administrator@*" {
        puts "✅ Миграция завершена"
    }
}

send "exit\r"
expect eof

