#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set ttk_repo_path "/var/www/estenomada/ttk_repo"

puts "🔍 Проверка результата push и очистка..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем статус
puts "\n📊 Статус репозитория:"
send "cd $ttk_repo_path && sudo -u www-data git status\r"
expect "administrator@*"

# Удаляем странный файл
puts "\n🧹 Удаляю странный файл..."
send "cd $ttk_repo_path && sudo -u www-data rm -f 'This account is currently not available.' 2>/dev/null; echo 'Файл удален'\r"
expect "administrator@*"

# Проверяем последние коммиты
puts "\n📋 Последние коммиты:"
send "cd $ttk_repo_path && sudo -u www-data git log --oneline -3\r"
expect "administrator@*"

# Проверяем связь с GitHub
puts "\n🔗 Проверка связи с GitHub:"
send "cd $ttk_repo_path && sudo -u www-data git fetch origin 2>&1 | head -5\r"
expect "administrator@*"

# Пробуем еще раз push для уверенности
puts "\n📤 Повторный push (если нужно):"
send "cd $ttk_repo_path && sudo -u www-data git push origin main 2>&1\r"
expect {
    "administrator@*" {
        puts "✅ Проверка завершена"
    }
}

send "exit\r"
expect eof

