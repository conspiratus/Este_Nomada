#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔧 Исправление admin.py..."

spawn scp backend/core/admin.py $server:/tmp/admin.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ admin.py загружен"

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
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

send "sudo mv /tmp/admin.py $remote_backend/core/admin.py\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ admin.py обновлен"
    }
}

send "sudo chown www-data:www-data $remote_backend/core/admin.py\r"
expect "administrator@*"

send "sudo chmod 644 $remote_backend/core/admin.py\r"
expect "administrator@*"

# Очищаем кэш
send "find $remote_backend -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; find $remote_backend -name '*.pyc' -delete 2>/dev/null; echo 'Кэш очищен'\r"
expect "administrator@*"

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

send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n✅ Готово! admin.py исправлен."

