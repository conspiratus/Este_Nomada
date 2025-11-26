#!/usr/bin/expect -f

# Детальная проверка логов Django

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю последние ошибки Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 50 --no-pager | grep -i 'error\\|exception\\|traceback' | tail -30"

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

puts "🔍 Проверяю логи доступа Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo tail -20 /var/www/estenomada/backend/logs/access.log 2>/dev/null | tail -10"

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

puts "🧪 Тестирую API с детальным выводом ошибки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s https://estenomada.es/api/hero/images/ 2>&1 | head -30"

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

