#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "🔧 Исправление ошибки с ttk_comments..."

# Загружаем актуальные файлы
puts "\n📤 Загрузка views.py..."
spawn scp backend/core/views.py $server:/tmp/views.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ views.py загружен"

puts "\n📤 Загрузка models.py..."
spawn scp backend/core/models.py $server:/tmp/models.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ models.py загружен"

puts "\n📤 Загрузка шаблона..."
spawn scp backend/core/templates/chef/ttk_view.html $server:/tmp/ttk_view.html
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
puts "✅ Шаблон загружен"

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

send "sudo mv /tmp/views.py $remote_backend/core/views.py\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ views.py обновлен"
    }
}

send "sudo mv /tmp/models.py $remote_backend/core/models.py\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ models.py обновлен"
    }
}

send "sudo mv /tmp/ttk_view.html $remote_backend/core/templates/chef/ttk_view.html\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Шаблон обновлен"
    }
}

send "sudo chown www-data:www-data $remote_backend/core/views.py $remote_backend/core/models.py $remote_backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"

send "sudo chmod 644 $remote_backend/core/views.py $remote_backend/core/models.py\r"
expect "administrator@*"

send "sudo chmod 755 $remote_backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"

# Очищаем кэш Python
puts "\n🧹 Очистка кэша Python..."
send "find $remote_backend -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true\r"
expect "administrator@*"
send "find $remote_backend -name '*.pyc' -delete 2>/dev/null || true\r"
expect "administrator@*"
puts "✅ Кэш очищен"

send "sudo systemctl start estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend перезапущен"
    }
}

send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n✅ Готово! Проверь страницу ТТК."

