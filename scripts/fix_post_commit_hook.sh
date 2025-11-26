#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔧 Исправление post-commit hook..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Удаляем старый hook (он использует sudo, что не работает)
puts "\n🗑️  Удаляю старый hook..."
send "cd $ttk_repo_path && sudo rm -f .git/hooks/post-commit\r"
expect "administrator@*"

# Создаем новый hook без sudo (git уже запускается от www-data)
puts "\n💡 Создаю новый hook..."
send "cd $ttk_repo_path && echo '#!/bin/bash' | sudo -u www-data tee .git/hooks/post-commit > /dev/null\r"
expect "administrator@*"

send "cd $ttk_repo_path && echo 'cd /var/www/estenomada/ttk_repo' | sudo -u www-data tee -a .git/hooks/post-commit > /dev/null\r"
expect "administrator@*"

send "cd $ttk_repo_path && echo 'git fetch origin 2>&1 || true' | sudo -u www-data tee -a .git/hooks/post-commit > /dev/null\r"
expect "administrator@*"

send "cd $ttk_repo_path && echo 'git pull --rebase origin main 2>&1 || git pull origin main --no-edit 2>&1 || true' | sudo -u www-data tee -a .git/hooks/post-commit > /dev/null\r"
expect "administrator@*"

send "cd $ttk_repo_path && echo 'git push origin main 2>&1 || true' | sudo -u www-data tee -a .git/hooks/post-commit > /dev/null\r"
expect "administrator@*"

send "cd $ttk_repo_path && sudo chmod +x .git/hooks/post-commit && sudo chown www-data:www-data .git/hooks/post-commit\r"
expect "administrator@*"

puts "\n✅ Hook обновлен"

# Проверяем содержимое
send "cd $ttk_repo_path && sudo -u www-data cat .git/hooks/post-commit\r"
expect "administrator@*"

send "exit\r"
expect eof

