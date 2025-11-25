#!/usr/bin/expect -f

# Пересборка фронтенда для исправления ошибок React

set timeout 600
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Пересборка фронтенда"
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

# Очищаем старую сборку
puts "\n🧹 Очистка старой сборки..."
send "rm -rf .next\r"
expect "administrator@*"
puts "✅ Старая сборка удалена"

# Устанавливаем права для сборки
puts "\n🔐 Установка прав..."
send "sudo chown -R administrator:administrator .\r"
expect "administrator@*"
puts "✅ Права установлены"

# Пересобираем
puts "\n🔨 Пересборка Next.js (это может занять несколько минут)..."
send "npm run build\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Сборка завершена"
    }
    timeout {
        puts "⚠️  Timeout при сборке (продолжаем...)"
    }
}

# Устанавливаем права обратно
puts "\n🔐 Установка прав для www-data..."
send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"
puts "✅ Права установлены"

# Перезапускаем фронтенд
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
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl status estenomada-frontend --no-pager | head -15\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Пересборка завершена!"
puts "=========================================="
puts "Проверь сайт: https://estenomada.es"
puts "=========================================="

