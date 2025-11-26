#!/usr/bin/expect -f

# Пересборка Next.js с правильной компиляцией Tailwind CSS

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "🛑 Останавливаю frontend сервис..."
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

puts "🧹 Очищаю старую сборку..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo rm -rf .next && echo '✅ .next удален'"

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

puts "📦 Проверяю зависимости..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && npm list tailwindcss postcss autoprefixer 2>&1 | head -5"

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

sleep 3

puts "🔍 Проверяю размер CSS файлов..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && find .next/static/css -name '*.css' -exec ls -lh {} \\; 2>/dev/null | head -5"

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

puts "🔄 Запускаю frontend сервис..."
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

sleep 2

puts "🧪 Тестирую CSS файлы..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/_next/static/css/eda708e55b288128.css 2>&1 | head -5"

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

