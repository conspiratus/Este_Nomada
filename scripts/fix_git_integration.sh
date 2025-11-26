#!/usr/bin/expect -f

set timeout 600
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Восстановление Git интеграции на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Останавливаем backend
puts "\n⏸️  Остановка backend..."
send "sudo systemctl stop estenomada-backend\r"
expect "administrator@*"

# Создаем бэкап старых файлов
puts "\n📦 Создаю бэкап..."
send "cd $backend_dir && sudo cp core/views.py core/views.py.backup && sudo cp core/models.py core/models.py.backup\r"
expect "administrator@*"

puts "\n✅ Бэкап создан. Теперь нужно загрузить правильные файлы из Git."
puts "\nЗапусти деплой через GitHub Actions или загрузи файлы вручную."

send "exit\r"
expect eof

