#!/usr/bin/expect -f

# Проверка и исправление nginx для /chef/

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Проверка и исправление nginx для /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем логи nginx
puts "\n🔍 Проверка логов nginx..."
send "sudo tail -20 /var/log/nginx/estenomada_error.log | grep -i chef\r"
expect "administrator@*"

# Проверяем текущую конфигурацию
puts "\n🔍 Проверка текущей конфигурации..."
send "sudo grep -A 10 'location.*chef' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Удаляем все старые location для chef
puts "\n🗑️  Удаление старых location для chef..."
send "sudo sed -i '/location.*chef/,/}/d' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Создаём правильную конфигурацию (более точную)
send "cat > /tmp/chef_location_correct.conf << 'EOFCONF'
    # Интерфейс повара - проксируем на Django backend (с локалями и без)
    location ~ ^/(en|es|ru)?/chef(/.*)?\$ {
        set \$locale_path \$1;
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
EOFCONF
\r"
expect "administrator@*"

# Вставляем перед location /
send "sudo sed -i '/location \\/ {/r /tmp/chef_location_correct.conf' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

# Проверяем синтаксис
puts "\n🔍 Проверка синтаксиса nginx..."
send "sudo nginx -t\r"
expect "administrator@*"

# Если синтаксис правильный, перезагружаем
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

# Проверяем доступность через curl
puts "\n🔍 Проверка доступности /en/chef..."
send "curl -I http://localhost/en/chef 2>&1 | head -5\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

