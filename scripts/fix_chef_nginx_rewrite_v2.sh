#!/usr/bin/expect -f

# Исправление rewrite для /chef/ (версия 2)

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление rewrite для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Удаляем старые location для chef
puts "\n🗑️  Удаление старых location..."
send "sudo sed -i '/location.*chef/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём правильную конфигурацию без rewrite, используя переменные
send "cat > /tmp/chef_rewrite_v2.conf << 'EOFCONF'
    # Интерфейс повара с локалями - используем переменные для правильного пути
    location ~ ^/(en|es|ru)/chef(/.*)?\$ {
        set \$chef_path \$2;
        if (\$chef_path = \"\") {
            set \$chef_path \"/\";
        }
        proxy_pass http://backend/chef\$chef_path;
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
send "sudo sed -i '/location \\/ {/r /tmp/chef_rewrite_v2.conf' /etc/nginx/sites-available/estenomada\r"
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
send "sudo grep -A 10 'location.*chef' /etc/nginx/sites-available/estenomada | head -25\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

