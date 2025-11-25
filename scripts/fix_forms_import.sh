#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔧 Исправление forms.py..."

spawn scp backend/core/forms.py $server:/tmp/forms.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ forms.py загружен"

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

send "sudo mv /tmp/forms.py $remote_backend/core/forms.py\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ forms.py обновлен"
    }
}

send "sudo chown www-data:www-data $remote_backend/core/forms.py\r"
expect "administrator@*"

send "sudo chmod 644 $remote_backend/core/forms.py\r"
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

puts "\n✅ Готово! forms.py исправлен."

