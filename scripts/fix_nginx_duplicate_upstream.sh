#!/usr/bin/expect -f

# Исправление дублирования upstream в nginx

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю конфигурации на дубликаты upstream..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "echo '=== estenomada ===' && sudo grep -A 3 'upstream frontend' /etc/nginx/sites-available/estenomada 2>/dev/null | head -5 && echo '' && echo '=== estenomada.production.conf ===' && sudo grep -A 3 'upstream frontend' /etc/nginx/sites-available/estenomada.production.conf 2>/dev/null | head -5"

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

puts "🔧 Отключаю старую конфигурацию estenomada..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo rm -f /etc/nginx/sites-enabled/estenomada && echo '✅ Старая конфигурация отключена'"

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

puts "🔧 Проверяю конфигурацию nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo nginx -t && echo '✅ Конфигурация валидна'"

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

puts "🔄 Перезагружаю nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl reload nginx && echo '✅ Nginx перезагружен'"

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

puts "🧪 Тестирую статические файлы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -I https://estenomada.es/_next/static/css/app/layout.css 2>&1 | grep -E 'HTTP|Content-Type|Content-Length' | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Исправление завершено"

