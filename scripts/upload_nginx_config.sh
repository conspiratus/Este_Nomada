#!/usr/bin/expect -f

# Загрузка правильной конфигурации nginx

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Загрузка правильной конфигурации nginx"
puts "=========================================="

spawn scp /Users/conspiratus/Projects/Este_Nomada/nginx/estenomada.production.conf $server:/tmp/estenomada_new.conf
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
send "sudo cp /etc/nginx/sites-available/estenomada /etc/nginx/sites-available/estenomada.backup_chef\r"
expect "administrator@*"

# Копируем новую конфигурацию
puts "\n📝 Копирование новой конфигурации..."
send "sudo cp /tmp/estenomada_new.conf /etc/nginx/sites-available/estenomada\r"
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
