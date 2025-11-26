#!/usr/bin/expect -f

# Проверка таблицы и перезапуск

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю, есть ли таблица menu_item_images..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SHOW TABLES LIKE \"menu_item%\";' 2>&1 | grep -v 'Warning'"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/menu/?locale=en' | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

