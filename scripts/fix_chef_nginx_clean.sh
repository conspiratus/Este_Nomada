#!/usr/bin/expect -f

# Очистка и правильная настройка nginx для /chef/

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Очистка и правильная настройка nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Удаляем ВСЕ location для chef (включая дубликаты)
puts "\n🗑️  Удаление всех location для chef..."
send "sudo sed -i '/location.*chef/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"
send "sudo sed -i '/# Интерфейс повара/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём правильную конфигурацию с простым rewrite
send "cat > /tmp/chef_clean.conf << 'EOFCONF'
    # Интерфейс повара с локалями - простой rewrite
    location ~ ^/(en|es|ru)/chef(/.*)?\$ {
        rewrite ^/(en|es|ru)/chef(/.*)?\$ /chef\$2 break;
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
EOFCONF
\r"
expect "administrator@*"

# Вставляем перед location /
send "sudo sed -i '/location \\/ {/r /tmp/chef_clean.conf' /etc/nginx/sites-available/estenomada\r"
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

# Проверяем финальную конфигурацию
puts "\n🔍 Проверка финальной конфигурации..."
send "sudo grep -c 'location.*chef' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"
send "sudo grep -A 8 'location.*chef' /etc/nginx/sites-available/estenomada | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

