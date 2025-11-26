#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔍 Проверка коммитов ТТК на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

puts "\n📋 Последние коммиты в локальном репозитории:"
send "cd $ttk_repo_path && sudo -u www-data git log --oneline -10\r"
expect "administrator@*"

puts "\n📊 Статус репозитория:"
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

puts "\n📁 Файлы в директории ttk:"
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/\r"
expect "administrator@*"

puts "\n🔗 Remote настройки:"
send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

puts "\n📤 Попытка push в GitHub:"
send "cd $ttk_repo_path && sudo -u www-data git push origin main 2>&1 || sudo -u www-data git push origin master 2>&1\r"
expect "administrator@*"

puts "\n💡 Проверка последних изменений файлов:"
send "cd $ttk_repo_path && sudo -u www-data git log --all --oneline --graph -10\r"
expect "administrator@*"

send "exit\r"
expect eof

