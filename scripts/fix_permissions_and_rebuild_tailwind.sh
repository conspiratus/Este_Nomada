#!/usr/bin/expect -f

# Исправление прав и пересборка с Tailwind CSS

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

puts "🔧 Исправляю права доступа..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo chown -R administrator:administrator .next 2>/dev/null; sudo rm -rf .next && echo '✅ .next удален'"

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

puts "📦 Пересобираю проект..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && npm run build"

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

puts "🔧 Устанавливаю правильные права на .next..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo chown -R www-data:www-data .next && echo '✅ Права установлены'"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl start estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Готово"
