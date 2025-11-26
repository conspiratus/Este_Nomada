#!/usr/bin/expect -f

set timeout 600
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set deploy_dir "/var/www/estenomada"
set backend_dir "$deploy_dir/backend"

puts "🔧 Полное исправление 502 Bad Gateway..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# 1. Исправляем frontend - переустанавливаем зависимости
puts "\n📦 Исправляем frontend..."
send "cd $deploy_dir && sudo systemctl stop estenomada-frontend\r"
expect "administrator@*"

send "cd $deploy_dir && sudo rm -rf node_modules package-lock.json\r"
expect "administrator@*"

send "cd $deploy_dir && sudo npm install 2>&1 | tail -5\r"
expect "administrator@*"

send "cd $deploy_dir && sudo chown -R www-data:www-data node_modules package-lock.json 2>/dev/null || true\r"
expect "administrator@*"

send "cd $deploy_dir && ls -la node_modules/next/package.json 2>&1\r"
expect "administrator@*"

# 2. Исправляем ALLOWED_HOSTS
puts "\n🔧 Исправляем ALLOWED_HOSTS..."
send "cd $backend_dir && sudo bash -c 'if grep -q \"^ALLOWED_HOSTS\" .env 2>/dev/null; then sed -i \"s|^ALLOWED_HOSTS=.*|ALLOWED_HOSTS=estenomada.es,www.estenomada.es,localhost,127.0.0.1,85.190.102.101|\" .env; else echo \"ALLOWED_HOSTS=estenomada.es,www.estenomada.es,localhost,127.0.0.1,85.190.102.101\" >> .env; fi'\r"
expect "administrator@*"

send "cd $backend_dir && sudo grep ALLOWED_HOSTS .env\r"
expect "administrator@*"

# 3. Перезапускаем сервисы
puts "\n🔄 Перезапускаем сервисы..."
send "sudo systemctl restart estenomada-backend\r"
expect "administrator@*"

send "sudo systemctl start estenomada-frontend\r"
expect "administrator@*"

send "sleep 5\r"
expect "administrator@*"

# 4. Проверяем статус
puts "\n📊 Проверяем статус..."
send "sudo systemctl status estenomada-backend --no-pager | head -8\r"
expect "administrator@*"

send "sudo systemctl status estenomada-frontend --no-pager | head -8\r"
expect "administrator@*"

# 5. Проверяем порты
puts "\n🔌 Проверяем порты..."
send "sudo ss -tlnp | grep -E '8000|3000'\r"
expect "administrator@*"

send "exit\r"
expect eof

