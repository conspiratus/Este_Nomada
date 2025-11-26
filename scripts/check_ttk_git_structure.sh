#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔍 Проверка структуры Git репозитория ТТК..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

puts "\n📁 Структура репозитория:"
send "cd $ttk_repo_path && sudo -u www-data find . -type f -name '*.md' | head -20\r"
expect "administrator@*"

puts "\n📂 Содержимое директории ttk:"
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/ 2>/dev/null || echo 'Директория ttk не найдена'\r"
expect "administrator@*"

puts "\n📋 История коммитов:"
send "cd $ttk_repo_path && sudo -u www-data git log --oneline --all -10\r"
expect "administrator@*"

puts "\n🌳 Дерево файлов в репозитории:"
send "cd $ttk_repo_path && sudo -u www-data git ls-tree -r --name-only HEAD\r"
expect "administrator@*"

puts "\n📊 Статус репозитория:"
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

puts "\n🔗 Remote репозитории:"
send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

send "exit\r"
expect eof

