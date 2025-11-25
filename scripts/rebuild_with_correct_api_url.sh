#!/usr/bin/expect -f

# Пересборка проекта с правильным API URL

set timeout 900
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

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

puts "🔍 Проверяю .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && echo 'Текущие переменные:' && grep -E '^NEXT_PUBLIC' .env.production"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && rm -rf .next && echo '✅ Директория .next удалена'"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && export NODE_ENV=production && source .env.production 2>/dev/null || true && npm run build"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 5

puts "✅ Проверяю результат сборки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && ls -la .next/BUILD_ID 2>/dev/null && echo '✅ Сборка завершена' || echo '❌ Ошибка сборки'"

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

