#!/usr/bin/expect -f

# Финальный запуск с загрузкой prerender-manifest.json

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Финальный запуск фронтенда"
puts "=========================================="

# Загружаем prerender-manifest.json
puts "\n📤 Загрузка prerender-manifest.json..."
spawn scp /tmp/prerender-manifest.json $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_dir\r"
expect "administrator@*"

# Копируем prerender-manifest.json
send "sudo cp /tmp/prerender-manifest.json .next/prerender-manifest.json\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Файл скопирован"
    }
}

send "sudo chown www-data:www-data .next/prerender-manifest.json\r"
expect "administrator@*"

# Запускаем фронтенд
puts "\n🚀 Запуск фронтенда..."
send "sudo systemctl restart estenomada-frontend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Фронтенд перезапущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 8\r"
expect "administrator@*"
send "sudo systemctl status estenomada-frontend --no-pager | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь сайт: https://estenomada.es"
puts "=========================================="

