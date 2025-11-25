#!/usr/bin/expect -f

# Тестирование cookie после логина

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🧪 Тестирую логин и проверку cookie..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST 'https://estenomada.es/api/auth/login/' -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}' -c /tmp/cookies.txt && echo '' && echo 'Cookies после логина:' && cat /tmp/cookies.txt"

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

puts "🧪 Тестирую /api/admin/auth/check с cookie..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X GET 'https://estenomada.es/api/admin/auth/check' -b /tmp/cookies.txt -c /tmp/cookies.txt | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

