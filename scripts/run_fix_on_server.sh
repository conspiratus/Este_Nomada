#!/usr/bin/expect -f

# Скрипт для запуска исправления Next.js на сервере через SSH

set timeout 600
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "📤 Загружаю скрипты на сервер..."
spawn scp -o StrictHostKeyChecking=no scripts/quick_fix_prerender.sh scripts/fix_nextjs_production.sh scripts/diagnose_and_fix_nextjs.sh $user@$host:/tmp/

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Скрипты загружены"
    }
}

# Копируем скрипты в рабочую директорию и запускаем диагностику
puts "🔍 Запускаю диагностику на сервере..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo cp /tmp/quick_fix_prerender.sh /tmp/fix_nextjs_production.sh /tmp/diagnose_and_fix_nextjs.sh scripts/ 2>/dev/null || cp /tmp/quick_fix_prerender.sh /tmp/fix_nextjs_production.sh /tmp/diagnose_and_fix_nextjs.sh scripts/ && chmod +x scripts/quick_fix_prerender.sh scripts/fix_nextjs_production.sh scripts/diagnose_and_fix_nextjs.sh && echo '✅ Скрипты скопированы' && echo '' && echo '🔍 Запускаю диагностику...' && bash scripts/diagnose_and_fix_nextjs.sh"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Диагностика завершена"
    }
}

# Ждем завершения диагностики, затем запускаем быстрое исправление
sleep 2

puts "🔧 Запускаю быстрое исправление..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && bash scripts/quick_fix_prerender.sh"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Исправление завершено"
    }
}

# Проверяем статус после исправления
sleep 2

puts "✅ Проверяю статус сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl status estenomada-frontend --no-pager -l | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Проверка завершена"
    }
}

