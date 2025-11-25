#!/usr/bin/expect -f

# Деплой исправления layout

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Деплой исправления layout"
puts "=========================================="

# Загружаем исправленный layout.tsx
puts "\n📤 Загрузка app/layout.tsx..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/app/layout.tsx $server:/tmp/layout.tsx
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

# Останавливаем фронтенд
puts "\n🛑 Остановка фронтенда..."
send "sudo systemctl stop estenomada-frontend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Фронтенд остановлен"
    }
}

# Копируем файл
puts "\n📥 Копирование файла..."
send "sudo cp /tmp/layout.tsx app/layout.tsx\r"
expect "administrator@*"
send "sudo chown www-data:www-data app/layout.tsx\r"
expect "administrator@*"

# Пересобираем фронтенд
puts "\n🔨 Пересборка фронтенда..."
send "sudo chown -R administrator:administrator .\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build 2>&1 | tail -30\r"
expect {
    "administrator@*" {
        puts "✅ Сборка завершена"
    }
    timeout {
        puts "⚠️  Timeout (продолжаем...)"
    }
}

# Устанавливаем права
send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Создаём prerender-manifest.json если его нет
puts "\n📝 Создание prerender-manifest.json..."
send "python3 -c \"import json; f=open('.next/prerender-manifest.json','w'); json.dump({'version':4,'routes':{},'dynamicRoutes':{},'notFoundRoutes':[],'preview':{'previewModeId':'','previewModeSigningKey':'','previewModeEncryptionKey':''}},f,indent=2); f.close()\"\r"
expect "administrator@*"
send "sudo chown www-data:www-data .next/prerender-manifest.json\r"
expect "administrator@*"

# Запускаем фронтенд
puts "\n🚀 Запуск фронтенда..."
send "sudo systemctl start estenomada-frontend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Фронтенд запущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 8\r"
expect "administrator@*"
send "sudo systemctl status estenomada-frontend --no-pager | head -20\r"
expect "administrator@*"

# Проверяем логи
puts "\n📋 Проверка логов..."
send "sudo journalctl -u estenomada-frontend -n 20 --no-pager\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь сайт: https://estenomada.es"
puts "=========================================="

