#!/usr/bin/expect -f

# Применение исправления маршрутизации API

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "📤 Загружаю исправленную конфигурацию nginx..."
spawn scp -o StrictHostKeyChecking=no nginx/estenomada.production.conf $user@$host:/tmp/estenomada.production.conf.fixed

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Конфигурация загружена"
    }
}

sleep 1

puts "🔧 Применяю конфигурацию..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/estenomada.production.conf.fixed /etc/nginx/sites-available/estenomada.production.conf && echo '✅ Конфигурация скопирована' && sudo nginx -t && echo '✅ Конфигурация валидна' && sudo systemctl reload nginx && echo '✅ Nginx перезагружен'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 3

puts "🧪 Тестирую API через nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "echo 'Тест 1: /api/hero/images/' && curl -sI https://estenomada.es/api/hero/images/ 2>&1 | head -8 && echo '' && echo 'Тест 2: /api/menu/?locale=ru' && curl -sI 'https://estenomada.es/api/menu/?locale=ru' 2>&1 | head -8"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Исправление применено"

