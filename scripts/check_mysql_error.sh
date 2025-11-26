#!/usr/bin/expect -f

# Проверка ошибки MySQL

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю последние ошибки в journalctl..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 50 --no-pager | grep -A 5 -i 'OperationalError\|Access denied\|Error\|Exception' | tail -30"

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

puts "🧪 Тестирую подключение к MySQL напрямую..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u czjey8yl0_estenomada -p'Jovi4AndMay2020!' -h localhost -e 'SELECT 1' 2>&1 | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

