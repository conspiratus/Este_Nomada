#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔍 Проверка статуса Git репозитория ТТК..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Последние коммиты
puts "\n📋 Последние коммиты:"
send "cd $ttk_repo_path && sudo -u www-data git --no-pager log --oneline -10\r"
expect "administrator@*"

# Статус
puts "\n📊 Статус репозитория:"
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

# Проверяем незакоммиченные изменения
puts "\n📝 Незакоммиченные изменения:"
send "cd $ttk_repo_path && sudo -u www-data git diff --stat\r"
expect "administrator@*"

# Проверяем remote
puts "\n🔗 Remote настройки:"
send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

# Проверяем последние изменения файлов
puts "\n📁 Последние изменения файлов:"
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/ && sudo -u www-data stat -c '%y %n' ttk/*.md 2>/dev/null | tail -3\r"
expect "administrator@*"

# Проверяем post-commit hook
puts "\n💡 Post-commit hook:"
send "cd $ttk_repo_path && sudo -u www-data cat .git/hooks/post-commit 2>&1\r"
expect "administrator@*"

# Пробуем push вручную
puts "\n📤 Пробую push вручную:"
send "cd $ttk_repo_path && timeout 15 sudo -u www-data git push origin main 2>&1\r"
expect "administrator@*"

# Проверяем логи Django на ошибки
puts "\n📋 Последние ошибки Django:"
send "sudo tail -50 /var/www/estenomada/backend/logs/error.log | grep -i 'ttk\|git\|error' | tail -10\r"
expect "administrator@*"

send "exit\r"
expect eof

