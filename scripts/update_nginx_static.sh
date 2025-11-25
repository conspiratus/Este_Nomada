#!/usr/bin/expect -f

set timeout 30
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Обновление Nginx конфигурации..."

# Загружаем конфиг
spawn scp nginx/estenomada.production.conf $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

# Применяем
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo cp /tmp/estenomada.production.conf /etc/nginx/sites-available/estenomada.production.conf\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}

puts "\n🧪 Тестирование конфигурации..."
send "sudo nginx -t\r"
expect "administrator@*"

puts "\n🔄 Перезагрузка Nginx..."
send "sudo systemctl reload nginx\r"
expect "administrator@*"

puts "\n🔍 Проверка /static/..."
send "curl -I https://estenomada.es/static/admin/css/base.css 2>&1 | grep -E '(HTTP|200|404)'\r"
expect "administrator@*"

puts "\n✅ Готово!"

send "exit\r"
expect eof


