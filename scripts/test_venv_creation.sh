#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_path "/var/www/estenomada/backend"

puts "🔍 Проверка создания venv на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем Python
send "which python3 && python3 --version\r"
expect "administrator@*"

# Проверяем текущий venv
send "cd $backend_path && ls -la venv/bin/ 2>/dev/null | head -10 || echo 'venv не существует'\r"
expect "administrator@*"

# Пробуем создать venv
send "cd $backend_path && sudo -u www-data python3 -m venv test_venv 2>&1\r"
expect "administrator@*"

send "cd $backend_path && ls -la test_venv/bin/ | head -5\r"
expect "administrator@*"

send "cd $backend_path && sudo rm -rf test_venv\r"
expect "administrator@*"

send "exit\r"
expect eof

