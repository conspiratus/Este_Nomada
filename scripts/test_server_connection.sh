#!/usr/bin/expect -f

# Тест подключения к серверу Next.js

set timeout 30
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🧪 Тестирую подключение к Next.js серверу..."
puts ""

# Тест локального подключения
puts "1️⃣ Тест локального подключения (localhost:3000)..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -I http://localhost:3000 2>&1 | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 1

# Тест через домен
puts ""
puts "2️⃣ Тест через домен (estenomada.es)..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -I https://estenomada.es 2>&1 | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 1

# Проверка статуса сервиса
puts ""
puts "3️⃣ Финальная проверка статуса сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl is-active estenomada-frontend && echo '✅ Сервис активен' || echo '❌ Сервис не активен'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts ""
puts "✅ Тестирование завершено"

