#!/usr/bin/expect -f

# Финальное исправление nginx для /chef/

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

# Создаём Python скрипт для исправления конфигурации
send "cat > /tmp/fix_nginx.py << 'EOFPY'
#!/usr/bin/env python3
import sys

with open('/etc/nginx/sites-available/estenomada', 'r') as f:
    lines = f.readlines()

# Находим location /api/ и добавляем после него location для chef
chef_config = '''        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Интерфейс повара - обрабатываем и с слэшем, и без
    location ^~ /en/chef/ {
        rewrite ^/en/chef/(.*) /chef/\\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /en/chef {
        return 301 /en/chef/;
    }
    location ^~ /es/chef/ {
        rewrite ^/es/chef/(.*) /chef/\\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /es/chef {
        return 301 /es/chef/;
    }
    location ^~ /ru/chef/ {
        rewrite ^/ru/chef/(.*) /chef/\\$1 break;
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /ru/chef {
        return 301 /ru/chef/;
    }
    location ^~ /chef/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host \\$host;
        proxy_set_header X-Real-IP \\$remote_addr;
        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    location = /chef {
        return 301 /chef/;
    }
'''

new_lines = []
i = 0
while i < len(lines):
    new_lines.append(lines[i])
    # Если нашли location /api/ и следующая строка пустая или содержит комментарий
    if 'location /api/' in lines[i] and i + 1 < len(lines):
        # Добавляем содержимое location /api/ и location для chef
        new_lines.append(chef_config)
        # Пропускаем пустые строки до следующего location или комментария
        i += 1
        while i < len(lines) and (lines[i].strip() == '' or lines[i].strip().startswith('#')):
            if 'location /' in lines[i] or 'location ~' in lines[i]:
                break
            i += 1
        continue
    i += 1

with open('/etc/nginx/sites-available/estenomada', 'w') as f:
    f.writelines(new_lines)
EOFPY
\r"
expect "administrator@*"

# Запускаем Python скрипт
puts "\n📝 Исправление конфигурации..."
send "sudo python3 /tmp/fix_nginx.py\r"
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
send "sudo sed -n '50,100p' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

