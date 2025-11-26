#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "📤 Загрузка обновленного git_utils.py..."

spawn scp backend/core/git_utils.py $server:/tmp/git_utils.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Останавливаем backend
send "sudo systemctl stop estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend остановлен"
    }
}

# Копируем файл
send "sudo cp /tmp/git_utils.py $remote_backend/core/git_utils.py\r"
expect "administrator@*"

send "sudo chown www-data:www-data $remote_backend/core/git_utils.py\r"
expect "administrator@*"

send "sudo chmod 644 $remote_backend/core/git_utils.py\r"
expect "administrator@*"

# Очищаем кэш
send "find $remote_backend -type d -name __pycache__ -exec sudo rm -rf {} + 2>/dev/null; find $remote_backend -name '*.pyc' -delete 2>/dev/null; echo 'Кэш очищен'\r"
expect "administrator@*"

# Запускаем backend
send "sudo systemctl start estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend запущен"
    }
}

send "sleep 2\r"
expect "administrator@*"

send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

