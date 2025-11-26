#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔍 Проверка статуса (без зависаний)..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Отключаем pager для всех git команд
send "cd $ttk_repo_path && sudo -u www-data git --no-pager log --oneline -5\r"
expect "administrator@*"

send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

send "cd $ttk_repo_path && sudo -u www-data git remote -v\r"
expect "administrator@*"

# Пробуем push с таймаутом
send "cd $ttk_repo_path && timeout 10 sudo -u www-data git push origin main 2>&1 || echo 'Push завершен или ошибка'\r"
expect "administrator@*"

send "exit\r"
expect eof

