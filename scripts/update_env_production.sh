#!/usr/bin/expect -f

# Обновление .env.production

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env.production 2>/dev/null | head -20 || echo 'Файл не найден'"

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

puts "🔧 Копирую настройки из .env в .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'cat .env | grep -E \"USE_SQLITE|DB_|ALLOWED_HOSTS|CORS_ALLOWED_ORIGINS\" > /tmp/db_settings.txt && cat /tmp/db_settings.txt'"

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

puts "🔧 Обновляю .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'if [ -f .env.production ]; then
    # Обновляем существующие строки или добавляем новые
    while IFS= read -r line; do
        key=\$(echo \"\$line\" | cut -d= -f1)
        if grep -q \"^\$key=\" .env.production 2>/dev/null; then
            sed -i \"s|^\$key=.*|\$line|\" .env.production
        else
            echo \"\$line\" >> .env.production
        fi
    done < /tmp/db_settings.txt
else
    cp .env .env.production
fi
echo \"✅ .env.production обновлен\"'"

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

puts "🔍 Проверяю обновленный .env.production..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env.production | grep -E 'USE_SQLITE|DB_' | sed 's/PASSWORD=.*/PASSWORD=***/'"

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

puts "🔄 Перезапускаю backend сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 5 && sudo systemctl status estenomada-backend --no-pager | head -10"

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

puts "🧪 Тестирую API..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/menu/?locale=en' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

