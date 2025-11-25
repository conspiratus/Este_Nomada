#!/usr/bin/expect -f

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "📤 Перезагрузка файлов ТТК..."

# Останавливаем backend
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

send "exit\r"
expect eof

# Загружаем файлы
puts "\n📤 Загрузка views.py..."
spawn scp backend/core/views.py $server:/tmp/views.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

puts "\n📤 Загрузка models.py..."
spawn scp backend/core/models.py $server:/tmp/models.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

puts "\n📤 Загрузка шаблона..."
spawn scp backend/core/templates/chef/ttk_view.html $server:/tmp/ttk_view.html
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся и перемещаем файлы
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "sudo mv /tmp/views.py $remote_backend/core/views.py\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ views.py перемещен"
    }
}

send "sudo mv /tmp/models.py $remote_backend/core/models.py\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ models.py перемещен"
    }
}

send "sudo mv /tmp/ttk_view.html $remote_backend/core/templates/chef/ttk_view.html\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Шаблон перемещен"
    }
}

send "sudo chown www-data:www-data $remote_backend/core/views.py $remote_backend/core/models.py $remote_backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"

send "sudo chmod 644 $remote_backend/core/views.py $remote_backend/core/models.py\r"
expect "administrator@*"

send "sudo chmod 755 $remote_backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"

# Очищаем кэш
puts "\n🧹 Очистка кэша..."
send "cd $remote_backend\r"
expect "administrator@*"
send "find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; find . -name '*.pyc' -delete 2>/dev/null; echo 'Кэш очищен'\r"
expect "administrator@*"

# Перезапускаем
puts "\n🔄 Перезапуск backend..."
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

puts "\n✅ Готово! Файлы обновлены."

