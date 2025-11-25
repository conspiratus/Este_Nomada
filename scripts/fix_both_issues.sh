#!/usr/bin/expect -f

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Исправление обеих проблем..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# 1. Исправляем backend - проверяем и применяем миграцию
puts "\n🔧 Исправление backend..."
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"
send "sudo -u www-data venv/bin/python3 manage.py showmigrations core\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}

send "sudo -u www-data venv/bin/python3 manage.py migrate core\r"
expect {
    "administrator@*" {
        puts "✅ Миграция применена"
    }
    timeout {
        puts "⚠️  Timeout"
    }
}

# 2. Исправляем frontend - создаем prerender-manifest.json
puts "\n🔧 Исправление frontend..."
send "cd /var/www/estenomada\r"
expect "administrator@*"

send "echo '{\"version\":4,\"routes\":{},\"dynamicRoutes\":{},\"notFoundRoutes\":[],\"preview\":{\"previewModeId\":\"\",\"previewModeSigningKey\":\"\",\"previewModeEncryptionKey\":\"\"}}' | sudo tee .next/prerender-manifest.json > /dev/null\r"
expect "administrator@*"
send "sudo chown www-data:www-data .next/prerender-manifest.json\r"
expect "administrator@*"
puts "✅ prerender-manifest.json создан"

# Перезапускаем оба сервиса
puts "\n🔄 Перезапуск сервисов..."
send "sudo systemctl restart estenomada-backend estenomada-frontend\r"
expect "administrator@*"
send "sleep 8\r"
expect "administrator@*"

# Проверяем статус
puts "\n📊 Статус:"
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"

# Проверяем сайт
puts "\n🔍 Проверка сайта..."
send "curl -I https://estenomada.es/ 2>&1 | grep HTTP\r"
expect "administrator@*"

puts "\n✅ Готово!"

send "exit\r"
expect eof



