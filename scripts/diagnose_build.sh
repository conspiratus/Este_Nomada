#!/usr/bin/expect -f

set timeout 30
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd /var/www/estenomada\r"
expect "administrator@*"

puts "\n📋 Проверка структуры .next:"
send "ls -la .next/ | head -20\r"
expect "administrator@*"

puts "\n📋 Проверка владельца .next:"
send "ls -ld .next\r"
expect "administrator@*"

puts "\n📋 Проверка prerender-manifest.json:"
send "ls -la .next/prerender-manifest.json 2>&1\r"
expect "administrator@*"

puts "\n📋 Проверка всех *manifest* файлов:"
send "find .next -name '*manifest*' -type f 2>/dev/null\r"
expect "administrator@*"

send "exit\r"
expect eof


