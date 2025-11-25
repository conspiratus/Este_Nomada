#!/usr/bin/expect -f

# Исправление prerender-manifest.json через Python

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Исправление prerender-manifest.json через Python"
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

# Создаём правильный файл через Python
puts "\n📝 Создание правильного prerender-manifest.json..."
send "python3 << 'PYEOF'\r"
expect ">"
send "import json\r"
expect ">"
send "data = {\r"
expect ">"
send "    'version': 4,\r"
expect ">"
send "    'routes': {},\r"
expect ">"
send "    'dynamicRoutes': {},\r"
expect ">"
send "    'notFoundRoutes': [],\r"
expect ">"
send "    'preview': {\r"
expect ">"
send "        'previewModeId': '',\r"
expect ">"
send "        'previewModeSigningKey': '',\r"
expect ">"
send "        'previewModeEncryptionKey': ''\r"
expect ">"
send "    }\r"
expect ">"
send "}\r"
expect ">"
send "with open('.next/prerender-manifest.json', 'w') as f:\r"
expect ">"
send "    json.dump(data, f, indent=2)\r"
expect ">"
send "PYEOF\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Файл создан"
    }
}

# Устанавливаем права
send "sudo chown www-data:www-data .next/prerender-manifest.json\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Права установлены"
    }
}

# Проверяем содержимое файла
puts "\n🔍 Проверка содержимого файла..."
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
send "sudo systemctl status estenomada-frontend --no-pager | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "=========================================="

