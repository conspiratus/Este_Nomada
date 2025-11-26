#!/usr/bin/expect -f

# Проверка исправления Mixed Content

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "✅ Проверяю статус сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl status estenomada-frontend --no-pager | head -10"

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

puts "🧪 Тестирую доступность API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/api/menu/?locale=ru 2>&1 | head -5"

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

puts "🧪 Тестирую доступность Hero API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/api/hero/images/ 2>&1 | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts ""
puts "✅ Проверка завершена"
puts ""
puts "Теперь в браузере:"
puts "1. Очисти кеш (Ctrl+Shift+R или Cmd+Shift+R)"
puts "2. Перезагрузи страницу"
puts "3. Mixed Content ошибки должны исчезнуть"

