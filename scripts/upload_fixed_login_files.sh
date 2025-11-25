#!/usr/bin/expect -f

# Загрузка исправленных файлов логина

set timeout 120
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "📤 Загружаю обновленные файлы..."
puts "1. app/api/admin/auth/login/route.ts"
spawn scp -o StrictHostKeyChecking=no app/api/admin/auth/login/route.ts $user@$host:/tmp/login_route.ts

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ login route загружен"
    }
}

sleep 2

puts "2. app/admin/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/page.tsx $user@$host:/tmp/admin_page.tsx

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ admin page загружен"
    }
}

sleep 2

puts "🔧 Копирую файлы с sudo..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/login_route.ts $project_dir/app/api/admin/auth/login/route.ts && sudo cp /tmp/admin_page.tsx $project_dir/app/admin/page.tsx && sudo chown -R www-data:www-data $project_dir/app/api $project_dir/app/admin && echo '✅ Файлы скопированы'"

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

