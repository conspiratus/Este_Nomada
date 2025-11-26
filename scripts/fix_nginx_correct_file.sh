#!/usr/bin/expect -f

# Исправление правильного файла конфигурации

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Исправление правильного файла конфигурации"
puts "=========================================="

spawn scp /Users/conspiratus/Projects/Este_Nomada/nginx/estenomada.production.conf $server:/tmp/estenomada.production.conf
expect {
    "password:" {
        send "$password\r"
    }
}

expect eof

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Создаём бэкап
puts "\n💾 Создание бэкапа..."
send "sudo cp /etc/nginx/sites-enabled/estenomada.production.conf /etc/nginx/sites-enabled/estenomada.production.conf.backup_chef\r"
expect "administrator@*"

# Копируем новую конфигурацию
puts "\n📝 Копирование новой конфигурации..."
send "sudo cp /tmp/estenomada.production.conf /etc/nginx/sites-enabled/estenomada.production.conf\r"
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

# Проверяем активную конфигурацию
puts "\n🔍 Проверка активной конфигурации..."
send "sudo nginx -T 2>&1 | grep -A 10 'location.*en.*chef' | head -15\r"
expect "administrator@*"

# Тестируем запрос
puts "\n🔍 Тестирование запроса..."
send "curl -s -o /dev/null -w '%{http_code}' -H 'Host: estenomada.es' http://127.0.0.1/en/chef/\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/en/chef"
puts "=========================================="

