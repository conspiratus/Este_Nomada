#!/usr/bin/expect -f

# Проверка статических файлов Next.js и пересборка при необходимости

set timeout 600
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔍 Проверяю структуру статических файлов Next.js..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && echo 'Структура .next/static:' && find .next/static -type f -name '*.css' -o -name '*.js' 2>/dev/null | head -10 || echo 'Файлы не найдены' && echo '' && echo 'Проверка через Next.js сервер:' && curl -s http://localhost:3000/_next/static/css/app/layout.css 2>&1 | head -3"

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

puts "🔧 Применяю исправленную конфигурацию nginx..."
spawn scp -o StrictHostKeyChecking=no nginx/estenomada.production.conf $user@$host:/tmp/estenomada.production.conf.fixed

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

spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/estenomada.production.conf.fixed /etc/nginx/sites-available/estenomada.production.conf && sudo nginx -t && sudo systemctl reload nginx && echo '✅ Nginx перезагружен'"

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

puts "🧪 Тестирую статические файлы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/_next/static/css/app/layout.css 2>&1 | head -5"

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

