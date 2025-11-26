#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"
set backend_path "/var/www/estenomada/backend"

puts "🔍 Проверка почему коммит не создается..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем, есть ли изменения в файле
puts "\n📝 Проверка изменений в файле:"
send "cd $ttk_repo_path && sudo -u www-data git diff ttk/6_Хинкали.md | head -30\r"
expect "administrator@*"

# Проверяем, добавлен ли файл в индекс
puts "\n📦 Проверка индекса:"
send "cd $ttk_repo_path && sudo -u www-data git status --short\r"
expect "administrator@*"

# Проверяем последние логи Django на ошибки при сохранении ТТК
puts "\n📋 Логи Django (последние 100 строк):"
send "sudo tail -100 $backend_path/logs/error.log | tail -30\r"
expect "administrator@*"

# Проверяем access.log на запросы к ttk_edit
puts "\n🌐 Последние запросы к ttk_edit:"
send "sudo tail -50 $backend_path/logs/access.log | grep 'ttk.*edit' | tail -5\r"
expect "administrator@*"

# Проверяем права на файл
puts "\n🔐 Права на файл:"
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/6_Хинкали.md\r"
expect "administrator@*"

# Проверяем, может файл уже закоммичен но не отправлен?
puts "\n📊 Проверка последнего коммита:"
send "cd $ttk_repo_path && sudo -u www-data git --no-pager log -1 --stat\r"
expect "administrator@*"

# Проверяем содержимое git_utils.py на сервере
puts "\n💻 Проверка git_utils.py:"
send "grep -n 'write_file\|commit' $backend_path/core/git_utils.py | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

