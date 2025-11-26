#!/usr/bin/expect -f

# Загрузка обновленного check route

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "📤 Загружаю обновленный check route..."
spawn scp -o StrictHostKeyChecking=no app/api/admin/auth/check/route.ts $user@$host:/tmp/check_route.ts

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ Файл загружен"
    }
}

sleep 2

puts "🔧 Копирую файл с sudo..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/check_route.ts $project_dir/app/api/admin/auth/check/route.ts && sudo chown -R www-data:www-data $project_dir/app/api && echo '✅ Файл обновлен'"

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

puts "🔄 Перезапускаю frontend сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 3 && sudo systemctl status estenomada-frontend --no-pager | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

