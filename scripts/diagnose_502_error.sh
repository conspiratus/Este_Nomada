#!/usr/bin/expect -f

# Диагностика ошибки 502 Bad Gateway

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю статус frontend сервиса..."
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

puts "🔍 Проверяю логи frontend сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-frontend -n 20 --no-pager | tail -15"

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

puts "🧪 Тестирую доступность Next.js на порту 3000..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI http://localhost:3000 2>&1 | head -5"

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

puts "🔍 Проверяю, слушает ли порт 3000..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo netstat -tlnp | grep :3000 || sudo ss -tlnp | grep :3000 || echo 'Порт 3000 не слушается'"

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

puts "🔍 Проверяю конфигурацию nginx upstream..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo grep -A 3 'upstream frontend' /etc/nginx/sites-enabled/estenomada.production.conf 2>/dev/null | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Диагностика завершена"

