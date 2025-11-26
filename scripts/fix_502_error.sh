#!/usr/bin/expect -f

set timeout 600
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set deploy_dir "/var/www/estenomada"
set backend_dir "$deploy_dir/backend"

puts "🔧 Исправление 502 Bad Gateway..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# 1. Устанавливаем зависимости для frontend
puts "\n📦 Устанавливаем зависимости frontend..."
send "cd $deploy_dir && sudo -u www-data npm install 2>&1 | tail -10\r"
expect "administrator@*"

# Проверяем что next установлен
send "cd $deploy_dir && ls -la node_modules/next 2>&1 | head -3\r"
expect "administrator@*"

# 2. Проверяем ALLOWED_HOSTS в settings.py
puts "\n🔍 Проверяем ALLOWED_HOSTS..."
send "cd $backend_dir && grep -A 5 'ALLOWED_HOSTS' este_nomada/settings.py | head -10\r"
expect "administrator@*"

# 3. Перезапускаем frontend
puts "\n🔄 Перезапускаем frontend..."
send "sudo systemctl restart estenomada-frontend\r"
expect "administrator@*"
send "sleep 3\r"
expect "administrator@*"

# Проверяем статус
send "sudo systemctl status estenomada-frontend --no-pager | head -10\r"
expect "administrator@*"

# Проверяем порт 3000
send "sudo ss -tlnp | grep 3000\r"
expect "administrator@*"

send "exit\r"
expect eof

