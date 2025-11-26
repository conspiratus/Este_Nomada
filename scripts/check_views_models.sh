#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверка views.py и models.py на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем chef_ttk_view функцию
puts "\n📄 Проверка chef_ttk_view в views.py:"
send "cd $backend_dir && grep -A 30 'def chef_ttk_view' core/views.py | head -35\r"
expect "administrator@*"

# Проверяем get_git_repo в models.py
puts "\n📄 Проверка get_git_repo в models.py:"
send "cd $backend_dir && grep -A 10 'def get_git_repo' core/models.py\r"
expect "administrator@*"

# Проверяем использование TTK_USE_GIT в views
puts "\n📄 Проверка использования Git в views:"
send "cd $backend_dir && grep -n 'TTK_USE_GIT\\|get_git_repo\\|TTKGitRepository' core/views.py\r"
expect "administrator@*"

# Проверяем импорты в views
puts "\n📄 Проверка импортов в views.py:"
send "cd $backend_dir && head -30 core/views.py | grep -E 'import|from'\r"
expect "administrator@*"

send "exit\r"
expect eof

