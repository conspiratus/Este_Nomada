#!/usr/bin/expect -f

# Проверка ошибок сервиса

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю логи frontend сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-frontend -n 30 --no-pager | tail -20"

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

puts "🔍 Проверяю статус backend сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl status estenomada-backend --no-pager | head -10"

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

puts "🧪 Тестирую локальный доступ к API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI http://localhost:8000/api/menu/?locale=ru 2>&1 | head -5"

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

