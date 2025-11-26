#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set deploy_dir "/var/www/estenomada"

puts "🔍 Проверка ошибок frontend..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем последние логи frontend
puts "\n📋 Последние логи estenomada-frontend:"
send "sudo journalctl -u estenomada-frontend -n 100 --no-pager | grep -A 5 -B 5 -i 'error\\|fail\\|exception' | tail -40\r"
expect "administrator@*"

# Проверяем, существует ли server.js
puts "\n📁 Проверка файлов frontend:"
send "cd $deploy_dir && ls -lah server.js package.json .next 2>&1\r"
expect "administrator@*"

# Пробуем запустить вручную и посмотреть ошибку
puts "\n🧪 Тестовый запуск server.js:"
send "cd $deploy_dir && sudo -u www-data /usr/bin/node server.js 2>&1 | head -20 || echo 'Ошибка запуска'\r"
expect {
    "Error" { expect "administrator@*" }
    "administrator@*" {}
    timeout { send "\r"; expect "administrator@*" }
}

# Проверяем содержимое server.js
puts "\n📄 Первые строки server.js:"
send "head -20 $deploy_dir/server.js\r"
expect "administrator@*"

# Проверяем systemd unit файл
puts "\n⚙️  Systemd unit файл:"
send "sudo cat /etc/systemd/system/estenomada-frontend.service | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof
