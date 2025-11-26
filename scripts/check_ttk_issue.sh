#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"
set backend_path "/var/www/estenomada/backend"

puts "🔍 Диагностика проблемы с коммитами ТТК..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

puts "\n📋 Проверка незакоммиченных изменений:"
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

puts "\n📝 Проверка diff:"
send "cd $ttk_repo_path && sudo -u www-data git diff ttk/ 2>&1 | head -30\r"
expect "administrator@*"

puts "\n📊 Последние логи Django (ошибки):"
send "sudo tail -50 $backend_path/logs/error.log | grep -i 'ttk\|git\|error' | tail -20\r"
expect "administrator@*"

puts "\n🔍 Проверка прав на файлы:"
send "cd $ttk_repo_path && sudo -u www-data ls -lah ttk/6_Хинкали.md\r"
expect "administrator@*"

puts "\n💡 Попытка создать коммит вручную (тест):"
send "cd $ttk_repo_path && sudo -u www-data git add ttk/ && sudo -u www-data git status --short\r"
expect "administrator@*"

send "exit\r"
expect eof

