#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔧 Разрешение конфликта merge..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Разрешаем конфликт - берем версию с сервера для ttk файла
puts "\n🔀 Разрешаю конфликт для ttk файла..."
send "cd $ttk_repo_path && sudo -u www-data git checkout --ours 'ttk/6_Хинкали.md' 2>&1\r"
expect "administrator@*"

# Для README берем версию из GitHub (она более полная)
send "cd $ttk_repo_path && sudo -u www-data git checkout --theirs README.md 2>&1 || sudo -u www-data git checkout --ours README.md 2>&1\r"
expect "administrator@*"

# Добавляем разрешенные файлы
send "cd $ttk_repo_path && sudo -u www-data git add 'ttk/6_Хинкали.md' README.md 2>&1\r"
expect "administrator@*"

# Завершаем merge
send "cd $ttk_repo_path && sudo -u www-data git --no-pager commit --no-edit 2>&1 || echo 'Коммит уже создан'\r"
expect "administrator@*"

# Отправляем
puts "\n📤 Отправляю в GitHub..."
send "cd $ttk_repo_path && timeout 15 sudo -u www-data git push origin main 2>&1\r"
expect "administrator@*"

# Проверяем статус
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

send "exit\r"
expect eof

