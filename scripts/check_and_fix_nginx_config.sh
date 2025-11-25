#!/usr/bin/expect -f

# Проверка и исправление конфигурации nginx

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю активные конфигурации nginx..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "ls -la /etc/nginx/sites-enabled/ && echo '' && echo 'Проверка на дубликаты upstream:' && sudo grep -r 'upstream frontend' /etc/nginx/sites-enabled/ 2>/dev/null"

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

puts "🔍 Проверяю текущую конфигурацию для estenomada.es..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo grep -A 10 'server_name estenomada.es' /etc/nginx/sites-enabled/* | head -30"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Проверка завершена"

