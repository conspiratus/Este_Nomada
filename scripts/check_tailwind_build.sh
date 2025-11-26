#!/usr/bin/expect -f

# Проверка сборки Tailwind CSS

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "🔍 Проверяю конфигурацию Tailwind..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && cat tailwind.config.ts | head -10"

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

puts "🔍 Проверяю PostCSS конфигурацию..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && cat postcss.config.mjs"

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

puts "🔍 Проверяю импорт globals.css в layout..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && grep -r 'globals.css' app/"

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

puts "🔍 Проверяю размер CSS файла после сборки..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && find .next -name '*.css' -type f -exec ls -lh {} \; | head -5"

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

puts "🔍 Проверяю содержимое CSS файла..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && find .next -name '*.css' -type f -exec head -20 {} \; | head -30"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Проверка завершена"

