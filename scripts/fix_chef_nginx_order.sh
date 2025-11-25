#!/usr/bin/expect -f

# Исправление порядка location для /chef/

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление порядка location для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем порядок location блоков
puts "\n🔍 Проверка порядка location блоков..."
send "sudo grep -n 'location' /etc/nginx/sites-available/estenomada | grep -E '(chef|api|/)' | head -10\r"
expect "administrator@*"

# Удаляем все location для chef
puts "\n🗑️  Удаление всех location для chef..."
send "sudo sed -i '/location.*chef/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"
send "sudo sed -i '/# Интерфейс повара/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём конфигурацию с правильным приоритетом (^~ имеет высокий приоритет)
send "cat > /tmp/chef_order.conf << 'EOFCONF'
    # Интерфейс повара - высокий приоритет (^~) ПЕРЕД location /
    location ^~ /en/chef {
        rewrite ^/en/chef(.*) /chef\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location ^~ /es/chef {
        rewrite ^/es/chef(.*) /chef\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location ^~ /ru/chef {
        rewrite ^/ru/chef(.*) /chef\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
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

# Вставляем ПЕРЕД location / (но после location /api/)
send "sudo sed -i '/^[[:space:]]*location \\/ {/r /tmp/chef_order.conf' /etc/nginx/sites-available/estenomada\r"
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

# Проверяем порядок
puts "\n🔍 Проверка порядка location..."
send "sudo grep -n 'location' /etc/nginx/sites-available/estenomada | grep -E '(chef|api|^[[:space:]]*location /)' | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

