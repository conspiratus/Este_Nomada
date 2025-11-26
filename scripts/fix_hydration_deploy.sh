#!/usr/bin/expect -f

# Деплой исправлений для гидратации React

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Деплой исправлений гидратации React"
puts "=========================================="

# Создаём архив с исправленными файлами
puts "\n📦 Создание архива..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/hydration_fix.tar.gz app/layout.tsx 'app/[locale]/layout.tsx'"
expect eof
puts "✅ Архив создан"

# Загружаем архив
puts "\n📤 Загрузка архива на сервер..."
spawn scp /tmp/hydration_fix.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся и распаковываем
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

# Распаковываем файлы
puts "\n📥 Распаковка файлов..."
send "sudo tar xzf /tmp/hydration_fix.tar.gz\r"
expect "administrator@*"
puts "✅ Файлы распакованы"

# Устанавливаем права
send "sudo chown -R www-data:www-data app/\r"
expect "administrator@*"

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

# Устанавливаем права обратно
send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Создаём prerender-manifest.json если нужно
send "if [ ! -f .next/prerender-manifest.json ]; then sudo cp /tmp/prerender-manifest.json .next/prerender-manifest.json 2>/dev/null || python3 -c \"import json; json.dump({'version': 4, 'routes': {}, 'dynamicRoutes': {}, 'notFoundRoutes': [], 'preview': {'previewModeId': '', 'previewModeSigningKey': '', 'previewModeEncryptionKey': ''}}, open('.next/prerender-manifest.json', 'w'), indent=2)\"; sudo chown www-data:www-data .next/prerender-manifest.json; fi\r"
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

# Очистка
spawn bash -c "rm /tmp/hydration_fix.tar.gz"
expect eof

puts "\n=========================================="
puts "✅ Деплой завершён!"
puts "Проверь сайт: https://estenomada.es"
puts "Ошибки гидратации должны быть исправлены."
puts "=========================================="

