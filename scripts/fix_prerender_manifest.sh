#!/usr/bin/expect -f

# Создание prerender-manifest.json

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Создание prerender-manifest.json"
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

# Создаём prerender-manifest.json
puts "\n📝 Создание prerender-manifest.json..."
send "cat > /tmp/prerender.json << 'EOF'\r"
expect ">"
send "{\r"
expect ">"
send "  \"version\": 4,\r"
expect ">"
send "  \"routes\": {},\r"
expect ">"
send "  \"dynamicRoutes\": {},\r"
expect ">"
send "  \"notFoundRoutes\": [],\r"
expect ">"
send "  \"preview\": {\r"
expect ">"
send "    \"previewModeId\": \"\",\r"
expect ">"
send "    \"previewModeSigningKey\": \"\",\r"
expect ">"
send "    \"previewModeEncryptionKey\": \"\"\r"
expect ">"
send "  }\r"
expect ">"
send "}\r"
expect ">"
send "EOF\r"
expect "administrator@*"

# Копируем файл
send "sudo cp /tmp/prerender.json .next/prerender-manifest.json\r"
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
expect "administrator@*"
puts "✅ Права установлены"

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

