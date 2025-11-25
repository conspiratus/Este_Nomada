#!/usr/bin/expect -f

# Тестирование проксирования статических файлов через nginx

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🧪 Тестирую проксирование статических файлов через nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "echo 'Тест 1: CSS через nginx:' && curl -sI https://estenomada.es/_next/static/css/30c18ccd8e97039f.css 2>&1 | head -8 && echo '' && echo 'Тест 2: JS через nginx:' && curl -sI https://estenomada.es/_next/static/chunks/117-744bf36b14dad30e.js 2>&1 | head -8"

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

puts "🔍 Проверяю логи nginx на ошибки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -20 /var/log/nginx/estenomada_error.log 2>/dev/null | grep -i '404\\|error' | head -10 || echo 'Ошибок не найдено'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Тестирование завершено"

