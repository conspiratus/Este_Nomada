#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "📤 Загрузка миграции для удаления комментариев..."

spawn scp backend/core/migrations/0018_remove_ttk_comments.py $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ Миграция загружена"

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo mv /tmp/0018_remove_ttk_comments.py $remote_backend/core/migrations/\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция перемещена"
    }
}

send "sudo chown www-data:www-data $remote_backend/core/migrations/0018_remove_ttk_comments.py\r"
expect "administrator@*"

send "cd $remote_backend\r"
expect "administrator@*"
send "source venv/bin/activate\r"
expect "administrator@*"
send "python manage.py migrate core\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Миграция применена"
    }
    timeout {
        puts "⚠️  Timeout (продолжаем...)"
    }
}

send "exit\r"
expect eof

puts "✅ Готово!"

