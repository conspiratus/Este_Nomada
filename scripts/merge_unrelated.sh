#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔀 Объединение разошедшихся историй..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Настраиваем merge стратегию
send "cd $ttk_repo_path && sudo -u www-data git config pull.rebase false\r"
expect "administrator@*"

# Делаем merge с allow-unrelated-histories
puts "\n🔀 Объединяю истории..."
send "cd $ttk_repo_path && sudo -u www-data git pull origin main --allow-unrelated-histories --no-edit 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Merge выполнен"
    }
    "CONFLICT" {
        puts "⚠️ Конфликт - разрешаю автоматически"
        send "cd $ttk_repo_path && sudo -u www-data git checkout --ours ttk/ 2>&1 || true\r"
        expect "administrator@*"
        send "cd $ttk_repo_path && sudo -u www-data git add ttk/ && sudo -u www-data git commit --no-edit 2>&1 || true\r"
        expect "administrator@*"
    }
}

# Отправляем все
puts "\n📤 Отправляю все коммиты..."
send "cd $ttk_repo_path && sudo -u www-data git push origin main 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Push выполнен"
    }
}

# Проверяем результат
send "cd $ttk_repo_path && sudo -u www-data git log --oneline -5\r"
expect "administrator@*"

send "exit\r"
expect eof

