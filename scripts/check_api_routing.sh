#!/usr/bin/expect -f

# Проверка маршрутизации API

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю конфигурацию nginx для /api/..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo grep -A 10 'location /api' /etc/nginx/sites-enabled/estenomada.production.conf 2>/dev/null | head -15"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "🧪 Тестирую локальный доступ к API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "echo 'Тест 1: /api/hero/images/' && curl -sI http://localhost:8000/api/hero/images/ 2>&1 | head -5 && echo '' && echo 'Тест 2: /api/hero/settings/' && curl -sI http://localhost:8000/api/hero/settings/ 2>&1 | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "🧪 Тестирую через nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "echo 'Тест 1: https://estenomada.es/api/hero/images/' && curl -sI https://estenomada.es/api/hero/images/ 2>&1 | head -5 && echo '' && echo 'Тест 2: https://estenomada.es/api/hero/settings/' && curl -sI https://estenomada.es/api/hero/settings/ 2>&1 | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "🔍 Проверяю доступные эндпоинты Django API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s http://localhost:8000/api/ 2>&1 | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Проверка завершена"

