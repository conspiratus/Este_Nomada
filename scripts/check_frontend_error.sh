#!/usr/bin/expect -f

# Проверка ошибки frontend

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю логи frontend сервиса..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-frontend -n 50 --no-pager | tail -30"

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

puts "🔍 Проверяю prerender-manifest.json..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cat /var/www/estenomada/.next/prerender-manifest.json 2>/dev/null | head -20 || echo 'Файл не найден'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

