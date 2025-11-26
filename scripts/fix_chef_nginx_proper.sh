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
puts "\n🗑️  Удаление неправильных location из внутри /api/..."
send "sudo sed -i '/# Интерфейс повара/,/location = \\/chef {/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём правильную конфигурацию
send "cat > /tmp/chef_proper.conf << 'EOFCONF'
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

# Находим строку с закрывающей скобкой location /api/ и вставляем после неё
puts "\n📝 Добавление location после /api/..."
send "sudo awk '/location \\/api\\// {found=1} found && /^[[:space:]]*}/ {print NR; exit}' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Вставляем после закрывающей скобки location /api/ (примерно строка 139)
send "sudo sed -i '139r /tmp/chef_proper.conf' /etc/nginx/sites-available/estenomada\r"
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
send "sudo sed -n '129,200p' /etc/nginx/sites-available/estenomada | head -30\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

