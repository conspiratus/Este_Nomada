#!/usr/bin/expect -f

# Загрузка конфигурационных файлов Tailwind и PostCSS

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "📤 Загружаю tailwind.config.ts..."
spawn scp -o StrictHostKeyChecking=no tailwind.config.ts $user@$host:$project_dir/tailwind.config.ts

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ tailwind.config.ts загружен"
    }
}

sleep 2

puts "📤 Загружаю postcss.config.mjs..."
spawn scp -o StrictHostKeyChecking=no postcss.config.mjs $user@$host:$project_dir/postcss.config.mjs

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts "✅ postcss.config.mjs загружен"
    }
}

sleep 2

puts "🔄 Пересобираю проект..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo systemctl stop estenomada-frontend && sudo chown -R administrator:administrator .next 2>/dev/null; sudo rm -rf .next && sudo mkdir -p .next && sudo chown -R www-data:www-data .next && npm run build && sudo chown -R www-data:www-data .next && sudo systemctl start estenomada-frontend && echo '✅ Проект пересобран'"

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

