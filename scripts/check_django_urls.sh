#!/usr/bin/expect -f

# Проверка URL в Django

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Проверка URL в Django"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $backend_dir\r"
expect "administrator@*"

# Проверяем URLs
puts "\n🔍 Проверка URLs в este_nomada/urls.py..."
send "grep -n 'chef' este_nomada/urls.py\r"
expect "administrator@*"

# Проверяем URLs в core/urls.py
puts "\n🔍 Проверка URLs в core/urls.py..."
send "cat core/urls.py | head -20\r"
expect "administrator@*"

# Проверяем доступность через Django shell
puts "\n🔍 Проверка доступности через Django..."
send "source venv/bin/activate && python manage.py shell -c \"from django.urls import reverse; print('Chef login URL:', reverse('chef:login'))\"\r"
expect "administrator@*"

send "exit\r"
expect eof

