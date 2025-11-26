#!/usr/bin/expect -f

# Проверка сервера Next.js и тестирование статических файлов

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔍 Проверяю какой сервер Next.js используется..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo systemctl cat estenomada-frontend | grep ExecStart && echo '' && echo 'Проверка server.js:' && ls -la server.js 2>/dev/null && echo '' && echo 'Проверка .next/server.js:' && ls -la .next/server.js 2>/dev/null"

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

puts "🧪 Тестирую реальные пути к статическим файлам..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && echo 'Тест 1: CSS файл с хешем:' && curl -sI http://localhost:3000/_next/static/css/30c18ccd8e97039f.css 2>&1 | head -5 && echo '' && echo 'Тест 2: JS файл:' && curl -sI http://localhost:3000/_next/static/chunks/117-744bf36b14dad30e.js 2>&1 | head -5"

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

puts "🔍 Проверяю build manifest для правильных путей..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && cat .next/build-manifest.json 2>/dev/null | head -30 || echo 'Файл не найден'"

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

