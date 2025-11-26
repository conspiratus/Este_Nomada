#!/usr/bin/expect -f

# Исправление .env Django с sudo

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю владельца .env файла..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "ls -la $backend_dir/.env 2>/dev/null || echo 'Файл не найден'"

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

puts "🔧 Добавляю ALLOWED_HOSTS в .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'if grep -q \"^ALLOWED_HOSTS\" .env 2>/dev/null; then sed -i \"s|^ALLOWED_HOSTS=.*|ALLOWED_HOSTS=estenomada.es,www.estenomada.es,localhost,127.0.0.1|\" .env; else echo \"ALLOWED_HOSTS=estenomada.es,www.estenomada.es,localhost,127.0.0.1\" >> .env; fi' && echo '✅ ALLOWED_HOSTS добавлен' && sudo grep ALLOWED_HOSTS .env"

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

puts "🔧 Добавляю CORS_ALLOWED_ORIGINS в .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'if grep -q \"^CORS_ALLOWED_ORIGINS\" .env 2>/dev/null; then sed -i \"s|^CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://estenomada.es,https://www.estenomada.es|\" .env; else echo \"CORS_ALLOWED_ORIGINS=https://estenomada.es,https://www.estenomada.es\" >> .env; fi' && echo '✅ CORS_ALLOWED_ORIGINS добавлен' && sudo grep CORS_ALLOWED_ORIGINS .env"

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

puts "🔄 Перезапускаю Django backend..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 3 && sudo systemctl is-active estenomada-backend && echo '✅ Backend перезапущен'"

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

puts "🧪 Тестирую API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/api/hero/images/ 2>&1 | head -8"

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

