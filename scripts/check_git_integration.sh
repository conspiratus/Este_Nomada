#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверка Git интеграции на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем наличие git_utils.py
puts "\n📁 Проверка файлов Git интеграции:"
send "cd $backend_dir && ls -la core/git_utils.py 2>&1\r"
expect "administrator@*"

# Проверяем настройки в settings.py
puts "\n⚙️  Проверка настроек TTK_USE_GIT:"
send "cd $backend_dir && grep -A 3 'TTK_USE_GIT' este_nomada/settings.py 2>&1\r"
expect "administrator@*"

# Проверяем .env файл
puts "\n🔧 Проверка .env файла:"
send "cd $backend_dir && grep -E 'TTK_USE_GIT|TTK_GIT' .env 2>&1 || echo 'Переменные не найдены'\r"
expect "administrator@*"

# Проверяем views.py - есть ли использование Git
puts "\n📄 Проверка views.py:"
send "cd $backend_dir && grep -A 5 'TTK_USE_GIT' core/views.py | head -10 2>&1\r"
expect "administrator@*"

# Проверяем модели - есть ли get_git_repo
puts "\n📄 Проверка models.py:"
send "cd $backend_dir && grep -A 3 'get_git_repo' core/models.py | head -5 2>&1\r"
expect "administrator@*"

# Проверяем наличие ttk_repo
puts "\n📁 Проверка Git репозитория:"
send "ls -la /var/www/estenomada/ttk_repo/.git 2>&1 | head -3\r"
expect "administrator@*"

send "exit\r"
expect eof

