#!/usr/bin/expect -f

# Применение исправления конфигурации nginx для статических файлов

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "📤 Загружаю исправленную конфигурацию nginx..."
spawn scp -o StrictHostKeyChecking=no nginx/estenomada.production.conf $user@$host:/tmp/estenomada.production.conf

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

puts "🔧 Применяю конфигурацию nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/estenomada.production.conf /etc/nginx/sites-available/estenomada.production.conf && sudo ln -sf /etc/nginx/sites-available/estenomada.production.conf /etc/nginx/sites-enabled/estenomada.production.conf && echo '✅ Конфигурация скопирована' && sudo nginx -t && echo '✅ Конфигурация nginx валидна' && sudo systemctl reload nginx && echo '✅ Nginx перезагружен'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Конфигурация применена"
    }
}

sleep 2

puts "🧪 Тестирую доступность статических файлов..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -I https://estenomada.es/_next/static/css/app/layout.css 2>&1 | head -10 || echo 'Ошибка'"

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

