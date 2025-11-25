#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Обновление мобильного меню..."

# Загружаем Header.tsx
spawn scp components/Header.tsx $server:/tmp/
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof
puts "✅ Файл загружен"

# Применяем на сервере
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo cp /tmp/Header.tsx /var/www/estenomada/components/\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo chown www-data:www-data /var/www/estenomada/components/Header.tsx\r"
expect "administrator@*"

# Пересобираем Next.js
puts "\n🔨 Пересборка Next.js..."
send "cd /var/www/estenomada\r"
expect "administrator@*"
send "sudo chown -R administrator:administrator .next\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build\r"
expect {
    "administrator@*" {
        puts "✅ Собран"
    }
    timeout {
        puts "⚠️  Timeout (продолжаем)"
    }
}

send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Перезапускаем frontend
puts "\n🔄 Перезапуск frontend..."
send "sudo systemctl restart estenomada-frontend\r"
expect "administrator@*"
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"

puts "\n✅ Готово! Теперь в мобильном меню нет выбора языка."

send "exit\r"
expect eof


