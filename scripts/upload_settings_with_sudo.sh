#!/usr/bin/expect -f

# Загрузка обновленного settings.py с sudo

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "📤 Загружаю обновленный settings.py во временную директорию..."
spawn scp -o StrictHostKeyChecking=no backend/este_nomada/settings.py $user@$host:/tmp/settings.py

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ settings.py загружен"
    }
}

sleep 2

puts "🔧 Копирую файл с sudo..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/settings.py $backend_dir/este_nomada/settings.py && sudo chown www-data:www-data $backend_dir/este_nomada/settings.py && echo '✅ settings.py скопирован'"

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

puts "🔄 Перезапускаю backend сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 3 && sudo systemctl status estenomada-backend --no-pager | head -10"

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

puts "🧪 Тестирую API через HTTPS..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST https://estenomada.es/api/auth/login/ -H 'Content-Type: application/json' -d '{\"username\":\"test\",\"password\":\"test\"}' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

