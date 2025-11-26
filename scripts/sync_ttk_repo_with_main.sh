#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔄 Настройка синхронизации ТТК репозитория с основным..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

puts "\n📝 Обновляю remote на основной репозиторий..."

# Удаляем старый remote
send "cd $ttk_repo_path && sudo -u www-data git remote remove origin 2>/dev/null; echo 'Старый remote удален'\r"
expect "administrator@*"

# Добавляем remote основного репозитория (без токена, так как push будет через локальный репозиторий)
send "cd $ttk_repo_path && sudo -u www-data git remote add origin https://github.com/conspiratus/Este_Nomada.git\r"
expect "administrator@*"

puts "\n✅ Remote настроен на основной репозиторий"

# Проверяем remote
send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

# Получаем последние изменения
puts "\n📥 Получаю последние изменения из GitHub..."
send "cd $ttk_repo_path && sudo -u www-data git fetch origin\r"
expect "administrator@*"

# Проверяем статус
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

puts "\n📋 Текущая структура:"
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/\r"
expect "administrator@*"

puts "\n✅ Настройка завершена!"
puts "\n💡 Теперь:"
puts "   - ТТК файлы на сервере находятся в: $ttk_repo_path/ttk/"
puts "   - Они синхронизированы с GitHub: https://github.com/conspiratus/Este_Nomada/tree/main/ttk"
puts "   - При редактировании через интерфейс шефа изменения коммитятся локально"
puts "   - Для синхронизации с GitHub можно настроить автоматический push или делать вручную"

send "exit\r"
expect eof

