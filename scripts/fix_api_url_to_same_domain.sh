#!/usr/bin/expect -f

# Исправление API URL на тот же домен

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔧 Исправляю NEXT_PUBLIC_API_URL на тот же домен..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sed -i 's|^NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=https://estenomada.es/api|' .env.production && echo '✅ NEXT_PUBLIC_API_URL исправлен' && echo '' && echo 'Проверка:' && grep NEXT_PUBLIC_API_URL .env.production"

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

puts "⚠️ Нужна пересборка проекта для применения изменений!"
puts "Запусти: bash scripts/fix_permissions_and_rebuild.sh"

puts "✅ Исправление завершено"

