#!/usr/bin/expect -f

# Развертывание функционала комментариев и редактирования ТТК

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Развертывание функционала комментариев ТТК"
puts "=========================================="

# Загружаем файлы
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/models.py $server:/tmp/models.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/views.py $server:/tmp/views.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/forms.py $server:/tmp/forms.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/urls.py $server:/tmp/urls.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/admin.py $server:/tmp/admin.py
expect {
    "password:" {
        send "$password\r"
    }
}
expect eof

spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/templates/chef/ttk_view.html $server:/tmp/ttk_view.html
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

# Останавливаем Django
puts "\n🛑 Остановка Django..."
send "sudo systemctl stop estenomada-backend\r"
expect "administrator@*"

# Копируем файлы
puts "\n📝 Копирование файлов..."
send "sudo cp /tmp/models.py /var/www/estenomada/backend/core/models.py\r"
expect "administrator@*"
send "sudo cp /tmp/views.py /var/www/estenomada/backend/core/views.py\r"
expect "administrator@*"
send "sudo cp /tmp/forms.py /var/www/estenomada/backend/core/forms.py\r"
expect "administrator@*"
send "sudo cp /tmp/urls.py /var/www/estenomada/backend/core/urls.py\r"
expect "administrator@*"
send "sudo cp /tmp/admin.py /var/www/estenomada/backend/core/admin.py\r"
expect "administrator@*"
send "sudo cp /tmp/ttk_view.html /var/www/estenomada/backend/core/templates/chef/ttk_view.html\r"
expect "administrator@*"

# Устанавливаем права
puts "\n🔐 Установка прав..."
send "sudo chown -R www-data:www-data /var/www/estenomada/backend/core/\r"
expect "administrator@*"
send "sudo chmod 644 /var/www/estenomada/backend/core/*.py\r"
expect "administrator@*"
send "sudo chmod 644 /var/www/estenomada/backend/core/templates/chef/*.html\r"
expect "administrator@*"

# Активируем venv и создаём миграцию
puts "\n🐍 Создание миграции..."
send "cd /var/www/estenomada/backend && source venv/bin/activate && python manage.py makemigrations core\r"
expect "administrator@*"

# Применяем миграцию
puts "\n🔄 Применение миграции..."
send "python manage.py migrate core\r"
expect "administrator@*"

# Запускаем Django
puts "\n▶️  Запуск Django..."
send "sudo systemctl start estenomada-backend\r"
expect "administrator@*"

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Функционал комментариев и редактирования ТТК развернут"
puts "=========================================="

