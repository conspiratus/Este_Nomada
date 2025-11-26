#!/usr/bin/expect -f

set timeout 600
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set deploy_dir "/var/www/estenomada"

puts "🔧 Исправление frontend..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Останавливаем frontend
puts "\n⏹️  Останавливаем frontend..."
send "sudo systemctl stop estenomada-frontend\r"
expect "administrator@*"

# Удаляем node_modules и переустанавливаем
puts "\n🧹 Очищаем и переустанавливаем зависимости..."
send "cd $deploy_dir && sudo rm -rf node_modules package-lock.json\r"
expect "administrator@*"

send "cd $deploy_dir && sudo -u www-data npm install 2>&1 | tail -15\r"
expect "administrator@*"

# Проверяем что next установлен
puts "\n✅ Проверяем установку..."
send "cd $deploy_dir && ls -la node_modules/next/package.json 2>&1\r"
expect "administrator@*"

# Проверяем .next директорию
send "cd $deploy_dir && ls -la .next 2>&1 | head -5\r"
expect "administrator@*"

# Пробуем запустить вручную для проверки
puts "\n🧪 Тестовый запуск..."
send "cd $deploy_dir && timeout 5 sudo -u www-data /usr/bin/node server.js 2>&1 || echo 'Тест завершен'\r"
expect {
    "Error" { expect "administrator@*" }
    "administrator@*" {}
    timeout { send "\r"; expect "administrator@*" }
}

# Запускаем frontend
puts "\n🚀 Запускаем frontend..."
send "sudo systemctl start estenomada-frontend\r"
expect "administrator@*"
send "sleep 5\r"
expect "administrator@*"

# Проверяем статус
send "sudo systemctl status estenomada-frontend --no-pager | head -15\r"
expect "administrator@*"

# Проверяем порт
send "sudo ss -tlnp | grep 3000\r"
expect "administrator@*"

send "exit\r"
expect eof

