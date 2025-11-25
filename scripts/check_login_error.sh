#!/usr/bin/expect -f

# Проверка ошибки логина

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🧪 Делаю тестовый запрос на логин..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST 'https://estenomada.es/api/auth/login/' -H 'Content-Type: application/json' -d '{\"username\":\"test\",\"password\":\"test\"}' > /dev/null 2>&1 && echo 'Запрос выполнен'"

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

puts "🔍 Проверяю последние ошибки в journalctl..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 100 --no-pager | grep -A 10 -i 'login\|auth\|error\|exception' | tail -40"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

