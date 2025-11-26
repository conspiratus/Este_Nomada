#!/usr/bin/expect -f

# Исправление приоритета location для /chef/

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление приоритета location для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Удаляем все location для chef
puts "\n🗑️  Удаление всех location для chef..."
send "sudo sed -i '/location.*chef/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём правильную конфигурацию с более высоким приоритетом (^~)
send "cat > /tmp/chef_location_priority.conf << 'EOFCONF'
    # Интерфейс повара - проксируем на Django backend (высокий приоритет)
    location ^~ /chef {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Интерфейс повара с локалями - проксируем на Django backend
    location ~ ^/(en|es|ru)/chef {
        rewrite ^/(en|es|ru)/chef(.*) /chef\$2 break;
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

# Вставляем перед location /api/
send "sudo sed -i '/location \\/api\\//i\\' /etc/nginx/sites-available/estenomada\r"
send "sudo sed -i '/location \\/api\\//r /tmp/chef_location_priority.conf' /etc/nginx/sites-available/estenomada\r"
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

# Проверяем доступность
puts "\n🔍 Проверка доступности..."
send "curl -L http://localhost/en/chef 2>&1 | head -10\r"
expect "administrator@*"

# Проверяем конфигурацию
puts "\n🔍 Проверка конфигурации..."
send "sudo grep -A 5 'location.*chef' /etc/nginx/sites-available/estenomada | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

