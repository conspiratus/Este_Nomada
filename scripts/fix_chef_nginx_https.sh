#!/usr/bin/expect -f

# Добавление location для /chef/ в HTTPS блок

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Добавление location для /chef/ в HTTPS блок"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Находим HTTPS блок (listen 443)
puts "\n🔍 Поиск HTTPS блока..."
send "sudo grep -n 'listen 443' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем, есть ли location для chef в HTTPS блоке
puts "\n🔍 Проверка location для chef в HTTPS блоке..."
send "sudo awk '/listen 443/,/^}/ {if (/location.*chef/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Находим строку с location / в HTTPS блоке
puts "\n🔍 Поиск location / в HTTPS блоке..."
send "sudo awk '/listen 443/,/^}/ {if (/^[[:space:]]*location \\/ {/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём конфигурацию для HTTPS блока
send "cat > /tmp/chef_https.conf << 'EOFCONF'
    # Интерфейс повара - обрабатываем и с слэшем, и без
    location ^~ /en/chef/ {
        rewrite ^/en/chef/(.*) /chef/\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /en/chef {
        return 301 /en/chef/;
    }
    location ^~ /es/chef/ {
        rewrite ^/es/chef/(.*) /chef/\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /es/chef {
        return 301 /es/chef/;
    }
    location ^~ /ru/chef/ {
        rewrite ^/ru/chef/(.*) /chef/\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /ru/chef {
        return 301 /ru/chef/;
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
    location = /chef {
        return 301 /chef/;
    }
EOFCONF
\r"
expect "administrator@*"

# Находим номер строки с location / в HTTPS блоке и вставляем перед ней
puts "\n📝 Добавление location в HTTPS блок..."
send "sudo awk '/listen 443/,/^}/ {if (/^[[:space:]]*location \\/ {/) {print NR; exit}}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Вставляем перед location / в HTTPS блоке (примерно строка 149)
send "sudo sed -i '148r /tmp/chef_https.conf' /etc/nginx/sites-available/estenomada\r"
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
puts "\n🔍 Проверка конфигурации в HTTPS блоке..."
send "sudo awk '/listen 443/,/^}/ {if (/location.*chef/) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada | head -5\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

