#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔄 Синхронизация и отправка коммитов..."

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

# Делаем pull с rebase чтобы сохранить локальные коммиты
puts "\n🔀 Объединяю изменения..."
send "cd $ttk_repo_path && sudo -u www-data git pull --rebase origin main 2>&1 || sudo -u www-data git pull origin main --no-edit 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Синхронизация выполнена"
    }
    "CONFLICT" {
        puts "⚠️ Конфликт - разрешаю"
        send "cd $ttk_repo_path && sudo -u www-data git checkout --ours 'ttk/6_Хинкали.md' 2>&1\r"
        expect "administrator@*"
        send "cd $ttk_repo_path && sudo -u www-data git add 'ttk/6_Хинкали.md' && sudo -u www-data git rebase --continue 2>&1 || true\r"
        expect "administrator@*"
    }
}

# Отправляем все коммиты
puts "\n📤 Отправляю коммиты в GitHub..."
send "cd $ttk_repo_path && timeout 20 sudo -u www-data git push origin main 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Push выполнен"
    }
}

# Проверяем результат
send "cd $ttk_repo_path && sudo -u www-data git --no-pager log --oneline -3\r"
expect "administrator@*"

send "exit\r"
expect eof

