#!/usr/bin/expect -f

set timeout 30
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Исправление prerender-manifest.json..."

# Загружаем правильный файл
spawn scp /tmp/prerender-manifest.json $server:/tmp/prerender-fixed.json
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo cp /tmp/prerender-fixed.json /var/www/estenomada/.next/prerender-manifest.json\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo chown www-data:www-data /var/www/estenomada/.next/prerender-manifest.json\r"
expect "administrator@*"

puts "\n✅ Файл обновлён, проверяем:"
send "cat /var/www/estenomada/.next/prerender-manifest.json\r"
expect "administrator@*"

puts "\n🔄 Перезапуск frontend..."
send "sudo systemctl restart estenomada-frontend\r"
expect "administrator@*"
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-frontend\r"
expect "administrator@*"

puts "\n✅ Готово!"

send "exit\r"
expect eof


