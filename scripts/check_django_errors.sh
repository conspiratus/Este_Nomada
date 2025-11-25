#!/usr/bin/expect -f

# Проверка ошибок Django

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю логи Django backend..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -30 /var/www/estenomada/backend/logs/error.log 2>/dev/null | tail -20 || echo 'Логи не найдены'"

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

puts "🧪 Тестирую API с правильным Host заголовком..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI -H 'Host: estenomada.es' http://localhost:8000/api/hero/images/ 2>&1 | head -8"

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

puts "🔍 Проверяю ALLOWED_HOSTS в Django settings..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "grep -i 'ALLOWED_HOSTS' /var/www/estenomada/backend/este_nomada/settings.py 2>/dev/null | head -3 || echo 'Файл не найден'"

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

