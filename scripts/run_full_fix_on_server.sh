#!/usr/bin/expect -f

# Скрипт для полного исправления Next.js на сервере через SSH

set timeout 900
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "📤 Загружаю обновленные скрипты на сервер..."
spawn scp -o StrictHostKeyChecking=no scripts/quick_fix_prerender.sh scripts/fix_nextjs_production.sh $user@$host:/tmp/

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Скрипты загружены"
    }
}

# Копируем скрипты и запускаем полное исправление
puts "🔧 Запускаю полное исправление на сервере..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo cp /tmp/quick_fix_prerender.sh /tmp/fix_nextjs_production.sh scripts/ 2>/dev/null || cp /tmp/quick_fix_prerender.sh /tmp/fix_nextjs_production.sh scripts/ && sudo chmod +x scripts/quick_fix_prerender.sh scripts/fix_nextjs_production.sh && echo '✅ Скрипты скопированы' && echo '' && echo '🔧 Запускаю быстрое исправление prerender-manifest.json...' && bash scripts/quick_fix_prerender.sh"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Быстрое исправление завершено"
    }
}

# Проверяем статус
sleep 3

puts "✅ Проверяю статус сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl status estenomada-frontend --no-pager -l | head -25"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Проверка завершена"
    }
}

# Проверяем логи на ошибки
sleep 2

puts "📋 Проверяю последние логи на ошибки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-frontend -n 30 --no-pager | grep -i 'error\\|fatal\\|cannot' || echo 'Ошибок не найдено'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Проверка логов завершена"
    }
}

