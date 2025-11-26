#!/usr/bin/expect -f

# Получение полной ошибки

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🧪 Делаю тестовый запрос..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s 'https://estenomada.es/api/menu/?locale=en' > /dev/null 2>&1 && echo 'Запрос выполнен'"

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

puts "🔍 Проверяю последние 30 строк journalctl..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 30 --no-pager"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

