#!/usr/bin/expect -f

# Загрузка и исправление prerender-manifest.json

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "📤 Загружаю правильный prerender-manifest.json..."
spawn scp -o StrictHostKeyChecking=no prerender-manifest.json $user@$host:/tmp/prerender-manifest.json

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Файл загружен"
    }
}

sleep 1

puts "🔧 Копирую файл в .next и устанавливаю права..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/prerender-manifest.json $remote_dir/.next/prerender-manifest.json && sudo chown www-data:www-data $remote_dir/.next/prerender-manifest.json && sudo chmod 644 $remote_dir/.next/prerender-manifest.json && echo '✅ Файл скопирован' && echo '' && echo 'Проверка валидности:' && python3 -m json.tool $remote_dir/.next/prerender-manifest.json > /dev/null && echo '✅ JSON валиден' || echo '❌ JSON невалиден'"

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

puts "🚀 Перезапускаю сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -12"

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

puts "🧪 Тестирую доступность..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI http://localhost:3000 2>&1 | head -5 && echo '' && curl -sI https://estenomada.es 2>&1 | head -5"

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

