#!/usr/bin/expect -f

# Исправление prerender-manifest.json и перезапуск

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Исправление prerender-manifest.json"
puts "=========================================="

# Создаём правильный prerender-manifest.json локально
set manifest_content {
{
  "version": 4,
  "routes": {},
  "dynamicRoutes": {},
  "notFoundRoutes": [],
  "preview": {
    "previewModeId": "",
    "previewModeSigningKey": "",
    "previewModeEncryptionKey": ""
  }
}
}

# Сохраняем локально
set f [open "/tmp/prerender-manifest.json" w]
puts $f $manifest_content
close $f

# Загружаем на сервер
puts "\n📤 Загрузка prerender-manifest.json..."
spawn scp /tmp/prerender-manifest.json $server:/tmp/prerender-manifest.json
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

# Копируем файл
puts "\n📥 Копирование файла..."
send "sudo cp /tmp/prerender-manifest.json .next/prerender-manifest.json\r"
expect "administrator@*"
send "sudo chown www-data:www-data .next/prerender-manifest.json\r"
expect "administrator@*"

# Проверяем файл
puts "\n🔍 Проверка файла..."
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
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl status estenomada-frontend --no-pager | head -15\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "=========================================="

