#!/usr/bin/expect -f

# Правильное исправление nginx для /chef/

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Правильное исправление nginx для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Удаляем неправильно вставленные location (они внутри location /api/)
puts "\n🗑️  Удаление неправильных location..."
send "sudo sed -i '/# Интерфейс повара/,/location = \\/chef {/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Находим HTTPS блок (с ssl_certificate)
puts "\n🔍 Поиск HTTPS блока..."
send "sudo grep -n 'ssl_certificate' /etc/nginx/sites-available/estenomada | head -1\r"
expect "administrator@*"

# Читаем HTTPS блок
puts "\n🔍 Чтение HTTPS блока..."
send "sudo awk '/ssl_certificate/,/^}/ {if (NR > 1 && NR < 50) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada | head -30\r"
expect "administrator@*"

# Находим location /api/ в HTTPS блоке
puts "\n🔍 Поиск location /api/ в HTTPS блоке..."
send "sudo awk '/ssl_certificate/,/^}/ {if (/location \\/api\\//) print NR\": \"\$0}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём конфигурацию
send "cat > /tmp/chef_correct.conf << 'EOFCONF'
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

# Находим номер строки с location /api/ в HTTPS блоке и вставляем после неё
puts "\n📝 Добавление location после /api/ в HTTPS блоке..."
send "sudo awk '/ssl_certificate/,/^}/ {if (/location \\/api\\//) {getline; if (/}/) print NR-1; else print NR}}' /etc/nginx/sites-available/estenomada | head -1\r"
expect "administrator@*"

# Вставляем после закрывающей скобки location /api/ (примерно строка 130)
send "sudo sed -i '130r /tmp/chef_correct.conf' /etc/nginx/sites-available/estenomada\r"
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

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

