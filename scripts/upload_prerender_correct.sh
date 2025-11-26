#!/usr/bin/expect -f

# Загрузка правильного prerender-manifest.json

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Загрузка правильного prerender-manifest.json"
puts "=========================================="

# Загружаем файл
puts "\n📤 Загрузка файла на сервер..."
spawn scp /tmp/prerender-manifest.json $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся и копируем
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_dir\r"
expect "administrator@*"
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

# Проверяем содержимое
send "cat .next/prerender-manifest.json\r"
expect "administrator@*"

# Перезапускаем фронтенд
puts "\n🔄 Перезапуск фронтенда..."
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
puts "✅ Готово! Проверь сайт: https://estenomada.es"
puts "=========================================="

