#!/usr/bin/expect -f

# Исправление nginx с точными location для /chef/

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление nginx с точными location"
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
send "sudo sed -i '/# Интерфейс повара/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём конфигурацию с точными location (высший приоритет)
send "cat > /tmp/chef_exact.conf << 'EOFCONF'
    # Интерфейс повара - точные location с высоким приоритетом
    location = /en/chef {
        return 301 /en/chef/;
    }
    location = /es/chef {
        return 301 /es/chef/;
    }
    location = /ru/chef {
        return 301 /ru/chef/;
    }
    location ~ ^/(en|es|ru)/chef/ {
        rewrite ^/(en|es|ru)/chef(/.*) /chef\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Интерфейс повара без локали
    location = /chef {
        return 301 /chef/;
    }
    location ^~ /chef/ {
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

# Вставляем перед location /api/ (высокий приоритет)
send "sudo sed -i '/location \\/api\\//r /tmp/chef_exact.conf' /etc/nginx/sites-available/estenomada\r"
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

# Проверяем конфигурацию
puts "\n🔍 Проверка конфигурации..."
send "sudo grep -A 3 'location.*chef' /etc/nginx/sites-available/estenomada | head -30\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

