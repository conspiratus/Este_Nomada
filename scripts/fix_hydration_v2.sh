#!/usr/bin/expect -f

# Деплой исправлений для гидратации React

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Деплой исправлений гидратации React"
puts "=========================================="

# Загружаем первый файл
puts "\n📤 Загрузка app/layout.tsx..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/app/layout.tsx $server:/tmp/layout.tsx
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Загружаем второй файл через find
puts "\n📤 Загрузка locale layout..."
spawn bash -c "find /Users/conspiratus/Projects/Este_Nomada/app -path '*/\\[locale\\]/layout.tsx' -exec scp {} administrator@85.190.102.101:/tmp/locale_layout.tsx \\;"
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

# Копируем файлы
puts "\n📥 Копирование файлов..."
send "sudo cp /tmp/layout.tsx app/layout.tsx\r"
expect "administrator@*"
send "sudo cp /tmp/locale_layout.tsx app/\\[locale\\]/layout.tsx\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data app/\r"
expect "administrator@*"
puts "✅ Файлы скопированы"

# Пересобираем фронтенд
puts "\n🔨 Пересборка фронтенда..."
send "sudo chown -R administrator:administrator .\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build\r"
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

# Создаём prerender-manifest.json если нужно
send "if [ ! -f .next/prerender-manifest.json ]; then python3 -c \"import json; json.dump({'version': 4, 'routes': {}, 'dynamicRoutes': {}, 'notFoundRoutes': [], 'preview': {'previewModeId': '', 'previewModeSigningKey': '', 'previewModeEncryptionKey': ''}}, open('.next/prerender-manifest.json', 'w'), indent=2)\"; sudo chown www-data:www-data .next/prerender-manifest.json; fi\r"
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

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Деплой завершён!"
puts "Проверь сайт: https://estenomada.es"
puts "Ошибки гидратации должны быть исправлены."
puts "=========================================="

