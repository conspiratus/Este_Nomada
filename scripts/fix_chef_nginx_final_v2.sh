#!/usr/bin/expect -f

# Финальное исправление nginx для /chef/ (версия 2)

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Финальное исправление nginx для /chef/"
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

# Находим номер строки с location /
puts "\n🔍 Поиск location /..."
send "sudo grep -n 'location / {' /etc/nginx/sites-available/estenomada | head -1\r"
expect "administrator@*"

# Создаём конфигурацию
send "cat > /tmp/chef_final_v2.conf << 'EOFCONF'
    # Интерфейс повара - высокий приоритет ПЕРЕД location /
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

# Вставляем перед location / (строка 78)
send "sudo sed -i '77r /tmp/chef_final_v2.conf' /etc/nginx/sites-available/estenomada\r"
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
send "sudo grep -n 'location' /etc/nginx/sites-available/estenomada | grep -E '(chef|^[0-9]+:.*location /)' | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

