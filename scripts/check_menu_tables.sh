#!/usr/bin/expect -f

# Проверка таблиц menu

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю все таблицы menu..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SHOW TABLES LIKE \"%menu%\" OR SHOW TABLES LIKE \"%attribute%\";' 2>&1 | grep -v 'Warning'"

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

puts "🔍 Проверяю структуру таблицы menu_items..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'DESCRIBE menu_items;' 2>&1 | grep -v 'Warning' | head -15"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

