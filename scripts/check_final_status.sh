#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔍 Проверка финального статуса..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

puts "\n📋 Последние коммиты на сервере:"
send "cd $ttk_repo_path && sudo -u www-data git log --oneline -5\r"
expect "administrator@*"

puts "\n📊 Статус репозитория:"
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

puts "\n🔗 Remote настройки:"
send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

puts "\n📤 Пробую push:"
send "cd $ttk_repo_path && sudo -u www-data git push origin main 2>&1 | head -10\r"
expect "administrator@*"

puts "\n💡 Проверка post-commit hook:"
send "cd $ttk_repo_path && sudo -u www-data ls -la .git/hooks/post-commit 2>&1\r"
expect "administrator@*"

send "exit\r"
expect eof

