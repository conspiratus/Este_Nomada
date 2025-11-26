#!/usr/bin/expect -f

# Исправление прав доступа и пересборка

set timeout 900
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔍 Проверяю доступность API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "echo 'Тест 1: https://api.estenomada.es/api/menu/' && curl -sI https://api.estenomada.es/api/menu/ 2>&1 | head -3 && echo '' && echo 'Тест 2: https://estenomada.es/api/menu/' && curl -sI https://estenomada.es/api/menu/ 2>&1 | head -3"

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

puts "🛑 Останавливаю сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl stop estenomada-frontend && echo '✅ Сервис остановлен'"

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

puts "🔧 Исправляю права доступа..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo chown -R $user:$user .next 2>/dev/null || true && echo '✅ Права исправлены'"

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

puts "🧹 Очищаю старую сборку..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo rm -rf .next && echo '✅ Директория .next удалена'"

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

puts "🔨 Пересобираю проект..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && export NODE_ENV=production && npm run build 2>&1 | tail -20"

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

puts "🔧 Устанавливаю правильные права на .next..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo chown -R www-data:www-data .next && echo '✅ Права установлены'"

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

puts "🚀 Запускаю сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl start estenomada-frontend && sleep 3 && sudo systemctl is-active estenomada-frontend && echo '✅ Сервис запущен'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Пересборка завершена"

