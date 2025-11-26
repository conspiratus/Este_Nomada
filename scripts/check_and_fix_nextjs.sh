#!/usr/bin/expect -f

# Проверка и исправление Next.js

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю статус сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl status estenomada-frontend --no-pager | head -15"

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

puts "🔍 Проверяю логи сервиса..."
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

puts "🔄 Перезапускаю сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl is-active estenomada-frontend && echo '✅ Сервис запущен'"

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

puts "🧪 Тестирую доступность..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/en 2>&1 | head -5"

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

