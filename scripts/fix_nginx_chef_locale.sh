#!/usr/bin/expect -f

# Исправление nginx для обработки /chef/ с локалями

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление nginx для /chef/ с локалями"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Создаём бэкап
puts "\n💾 Создание бэкапа..."
send "sudo cp /etc/nginx/sites-available/estenomada /etc/nginx/sites-available/estenomada.backup2\r"
expect "administrator@*"

# Читаем текущую конфигурацию location /chef/
puts "\n🔍 Проверка текущей конфигурации..."
send "sudo grep -A 10 'location /chef' /etc/nginx/sites-available/estenomada | head -15\r"
expect "administrator@*"

# Добавляем location для /en/chef/, /es/chef/, /ru/chef/ перед location /
puts "\n📝 Добавление location для локализованных путей..."
send "sudo sed -i '/location \\/ {/i\\    # Интерфейс повара с локалями - проксируем на Django backend\\n    location ~ ^/(en|es|ru)/chef(/|$) {\\n        proxy_pass http://backend;\\n        proxy_http_version 1.1;\\n        proxy_set_header Host \\\$host;\\n        proxy_set_header X-Real-IP \\\$remote_addr;\\n        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;\\n        proxy_set_header X-Forwarded-Proto \\\$scheme;\\n        proxy_read_timeout 300s;\\n        proxy_connect_timeout 75s;\\n        rewrite ^/(en|es|ru)/chef(/.*)?$ /chef\\$2 break;\\n    }\\n' /etc/nginx/sites-available/estenomada\r"
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

# Проверяем новую конфигурацию
puts "\n🔍 Проверка новой конфигурации..."
send "sudo grep -A 12 'location ~.*chef' /etc/nginx/sites-available/estenomada | head -15\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef/"
puts "=========================================="

