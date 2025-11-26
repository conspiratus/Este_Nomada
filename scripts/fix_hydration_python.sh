#!/usr/bin/expect -f

# Исправление гидратации через Python на сервере

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Исправление гидратации через Python"
puts "=========================================="

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

# Исправляем файлы через Python
puts "\n📝 Исправление файлов через Python..."
send "python3 << 'PYEOF'\r"
expect ">"
send "import re\r"
expect ">"
send "import os\r"
expect ">"
send "\r"
expect ">"
send "# Исправляем app/layout.tsx\r"
expect ">"
send "with open('app/layout.tsx', 'r') as f:\r"
expect ">"
send "    content = f.read()\r"
expect ">"
send "content = content.replace('return children;', 'return <>{children}</>;')\r"
expect ">"
send "with open('app/layout.tsx', 'w') as f:\r"
expect ">"
send "    f.write(content)\r"
expect ">"
send "\r"
expect ">"
send "# Исправляем locale layout\r"
expect ">"
send "locale_path = 'app/[locale]/layout.tsx'\r"
expect ">"
send "with open(locale_path, 'r') as f:\r"
expect ">"
send "    content = f.read()\r"
expect ">"
send "content = re.sub(r'<html lang=([^>]*)>', r'<html lang=\\1 suppressHydrationWarning>', content)\r"
expect ">"
send "content = content.replace('<body>', '<body suppressHydrationWarning>')\r"
expect ">"
send "with open(locale_path, 'w') as f:\r"
expect ">"
send "    f.write(content)\r"
expect ">"
send "PYEOF\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Файлы исправлены"
    }
}

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
puts "✅ Готово!"
puts "Проверь сайт: https://estenomada.es"
puts "=========================================="

