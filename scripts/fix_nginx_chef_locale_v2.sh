#!/usr/bin/expect -f

# Исправление nginx для обработки /chef/ с локалями (версия 2)

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

# Создаём временный файл с новой конфигурацией
puts "\n📝 Создание временного файла с конфигурацией..."
send "cat > /tmp/chef_location.conf << 'EOFCONF'
    # Интерфейс повара с локалями - проксируем на Django backend
    location ~ ^/(en|es|ru)/chef(/|\\$) {
        rewrite ^/(en|es|ru)/chef(/.*)?\\$ /chef\$2 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
EOFCONF
\r"
expect "administrator@*"

# Вставляем новую конфигурацию перед location /
puts "\n📝 Вставка конфигурации в nginx..."
send "sudo sed -i '/location \\/ {/r /tmp/chef_location.conf' /etc/nginx/sites-available/estenomada\r"
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

