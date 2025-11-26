#!/usr/bin/expect -f

# Исправление NEXT_PUBLIC_API_URL на сервере

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔍 Проверяю текущий .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && cat .env.production 2>/dev/null | grep -E 'NEXT_PUBLIC_API_URL|NEXT_PUBLIC_BASE_URL' || echo 'Переменные не найдены'"

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

puts "🔧 Устанавливаю правильный NEXT_PUBLIC_API_URL..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && if grep -q '^NEXT_PUBLIC_API_URL' .env.production 2>/dev/null; then sed -i 's|^NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=https://api.estenomada.es/api|' .env.production; else echo 'NEXT_PUBLIC_API_URL=https://api.estenomada.es/api' >> .env.production; fi && echo '✅ NEXT_PUBLIC_API_URL установлен' && echo '' && echo 'Проверка:' && grep NEXT_PUBLIC_API_URL .env.production"

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

puts "🔄 Перезапускаю сервис для применения изменений..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && echo '✅ Сервис перезапущен'"

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

puts "⚠️ ВАЖНО: Переменные NEXT_PUBLIC_* встраиваются в сборку!"
puts "Нужно пересобрать проект:"
puts "  cd /var/www/estenomada"
puts "  npm run build"
puts "  sudo systemctl restart estenomada-frontend"

puts "✅ Проверка завершена"

