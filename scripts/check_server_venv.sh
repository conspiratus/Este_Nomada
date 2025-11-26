#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_path "/var/www/estenomada/backend"

puts "🔍 Проверка venv на сервере..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем текущий venv
send "cd $backend_path && ls -la venv/bin/ 2>/dev/null | grep -E 'pip|python' | head -10 || echo 'venv/bin не существует'\r"
expect "administrator@*"

# Проверяем, работает ли source activate
send "cd $backend_path && sudo -u www-data bash -c 'source venv/bin/activate && which pip && pip --version' 2>&1\r"
expect "administrator@*"

# Проверяем путь к Python
send "which python3 && python3 --version\r"
expect "administrator@*"

send "exit\r"
expect eof

