#!/usr/bin/expect -f

# Применение исправленной конфигурации nginx

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "📤 Загружаю исправленную конфигурацию..."
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

puts "🔧 Применяю исправленную конфигурацию..."
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

puts "🧪 Тестирую статические файлы через Next.js..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/_next/static/css/app/layout.css 2>&1 | head -8"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Применение завершено"

