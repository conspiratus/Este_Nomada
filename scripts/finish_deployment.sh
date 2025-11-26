#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Завершение развертывания"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd /var/www/estenomada\r"
expect "administrator@*"

# Создаем prerender-manifest.json локально и загружаем
send "exit\r"
expect eof

puts "\n📤 Загрузка prerender-manifest.json..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/.next/prerender-manifest.json $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ Файл загружен"

# Подключаемся снова
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo cp /tmp/prerender-manifest.json /var/www/estenomada/.next/prerender-manifest.json\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo chown www-data:www-data /var/www/estenomada/.next/prerender-manifest.json\r"
expect "administrator@*"
puts "✅ prerender-manifest.json установлен"

# Запускаем сервисы
puts "\n🚀 Запуск сервисов..."
send "sudo systemctl start estenomada-backend estenomada-frontend\r"
expect "administrator@*"
send "sleep 8\r"
expect "administrator@*"

# Проверяем статус
puts "\n📊 Проверка статуса..."
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"
send "sudo systemctl is-active nginx\r"
expect "administrator@*"

puts "\n=========================================="
puts "✅ ГОТОВО!"
puts "=========================================="
puts "Сайт полностью развернут на продакшн:"
puts "- Frontend: https://estenomada.es"
puts "- Django Admin: https://estenomada.es/admin/"
puts ""
puts "Логин: admin"
puts "Пароль: admin123"
puts "=========================================="

send "exit\r"
expect eof



