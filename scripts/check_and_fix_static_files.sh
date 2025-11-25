#!/usr/bin/expect -f

# Проверка и исправление статических файлов Next.js

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔍 Проверяю наличие статических файлов..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && echo 'Проверка .next/static:' && ls -la .next/static 2>/dev/null | head -10 || echo '❌ Директория .next/static не существует' && echo '' && echo 'Проверка структуры .next:' && ls -la .next/ 2>/dev/null | head -15 || echo '❌ Директория .next не существует'"

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

puts "🔍 Проверяю конфигурацию nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo grep -A 5 'location /_next/static' /etc/nginx/sites-enabled/* 2>/dev/null | head -20 || echo 'Конфигурация не найдена'"

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

puts "🧪 Тестирую доступность статических файлов через Next.js..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -I http://localhost:3000/_next/static/css/app/layout.css 2>&1 | head -5 || echo 'Файл не найден'"

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

