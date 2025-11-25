#!/usr/bin/expect -f

# Загрузка исправленных файлов аутентификации

set timeout 120
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "📤 Загружаю обновленные файлы..."
puts "1. app/admin/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/page.tsx $user@$host:/tmp/admin_page.tsx

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ admin/page.tsx загружен"
    }
}

sleep 2

puts "2. lib/auth.ts"
spawn scp -o StrictHostKeyChecking=no lib/auth.ts $user@$host:/tmp/auth.ts

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ auth.ts загружен"
    }
}

sleep 2

puts "3. middleware.ts"
spawn scp -o StrictHostKeyChecking=no middleware.ts $user@$host:/tmp/middleware.ts

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ middleware.ts загружен"
    }
}

sleep 2

puts "🔧 Копирую файлы с sudo..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cp /tmp/admin_page.tsx $project_dir/app/admin/page.tsx && sudo cp /tmp/auth.ts $project_dir/lib/auth.ts && sudo cp /tmp/middleware.ts $project_dir/middleware.ts && sudo chown -R www-data:www-data $project_dir/app/admin $project_dir/lib $project_dir/middleware.ts && echo '✅ Файлы скопированы'"

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

puts "🔄 Пересобираю Next.js проект..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo -u www-data npm run build 2>&1 | tail -30"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

