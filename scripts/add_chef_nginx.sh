#!/usr/bin/expect -f

# Добавление location /chef/ в nginx

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Добавление location /chef/ в nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Читаем текущую конфигурацию
puts "\n🔍 Чтение текущей конфигурации..."
send "sudo cat /etc/nginx/sites-available/estenomada | head -80\r"
expect "administrator@*"

# Создаём бэкап
puts "\n💾 Создание бэкапа..."
send "sudo cp /etc/nginx/sites-available/estenomada /etc/nginx/sites-available/estenomada.backup.$(date +%Y%m%d_%H%M%S)\r"
expect "administrator@*"

# Добавляем location /chef/ перед location /
puts "\n📝 Добавление location /chef/..."
send "sudo sed -i '/location \\/ {/i\\    # Интерфейс повара - проксируем на Django backend\\n    location /chef/ {\\n        proxy_pass http://localhost:8000;\\n        proxy_http_version 1.1;\\n        proxy_set_header Host \\$host;\\n        proxy_set_header X-Real-IP \\$remote_addr;\\n        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;\\n        proxy_set_header X-Forwarded-Proto \\$scheme;\\n        proxy_read_timeout 300s;\\n        proxy_connect_timeout 75s;\\n    }\\n' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем синтаксис
puts "\n🔍 Проверка синтаксиса nginx..."
send "sudo nginx -t\r"
expect "administrator@*"

# Перезагружаем nginx
puts "\n🔄 Перезагрузка nginx..."
send "sudo systemctl reload nginx\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Nginx перезагружен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса nginx..."
send "sudo systemctl status nginx --no-pager | head -10\r"
expect "administrator@*"

# Проверяем логи Django для ошибки 500
puts "\n🔍 Проверка логов Django..."
send "sudo tail -30 /var/www/estenomada/backend/logs/error.log\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/chef/"
puts "=========================================="

