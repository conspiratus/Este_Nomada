#!/usr/bin/expect -f

# Удаление backup файла и перезапуск nginx

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Удаление backup файла и перезапуск nginx"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Перемещаем backup в другое место
puts "\n📦 Перемещение backup файла..."
send "sudo mv /etc/nginx/sites-enabled/estenomada.production.conf.backup_chef /tmp/\r"
expect "administrator@*"

# Проверяем синтаксис
puts "\n🔍 Проверка синтаксиса nginx..."
send "sudo nginx -t\r"
expect "administrator@*"

# Перезапускаем nginx
puts "\n🔄 Перезапуск nginx..."
send "sudo systemctl restart nginx\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Nginx перезапущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sudo systemctl status nginx --no-pager | head -10\r"
expect "administrator@*"

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

