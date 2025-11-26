#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔄 Синхронизация репозиториев..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Получаем изменения из GitHub
puts "\n📥 Получаю изменения из GitHub..."
send "cd $ttk_repo_path && sudo -u www-data git fetch origin\r"
expect "administrator@*"

# Делаем merge
puts "\n🔀 Объединяю изменения..."
send "cd $ttk_repo_path && sudo -u www-data git merge origin/main --no-edit 2>&1 || sudo -u www-data git pull origin main --no-edit 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Merge выполнен"
    }
    "CONFLICT" {
        puts "⚠️ Конфликт - нужно разрешить вручную"
    }
}

# Отправляем все коммиты
puts "\n📤 Отправляю все коммиты в GitHub..."
send "cd $ttk_repo_path && sudo -u www-data git push origin main 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Push выполнен"
    }
}

# Проверяем статус
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

# Проверяем последние коммиты
send "cd $ttk_repo_path && sudo -u www-data git log --oneline -5\r"
expect "administrator@*"

send "exit\r"
expect eof

