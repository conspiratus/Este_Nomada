#!/usr/bin/expect -f

# Загрузка миграции 0017 и templates на сервер

set timeout 180
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_backend "/var/www/estenomada/backend"

puts "=========================================="
puts "Загрузка миграции и templates ТТК"
puts "=========================================="

# 1. Загружаем миграцию
puts "\n📤 Загрузка миграции 0017..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/migrations/0017_dishttk.py $server:$remote_backend/core/migrations/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# 2. Загружаем templates
puts "\n📤 Загрузка templates..."
spawn bash -c "cd /Users/conspiratus/Projects/Este_Nomada && tar czf /tmp/chef_templates.tar.gz -C backend/core templates/chef/"
expect eof

spawn scp /tmp/chef_templates.tar.gz $server:/tmp/
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# 3. Подключаемся к серверу
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_backend\r"
expect "administrator@*"

# Распаковываем templates
puts "\n📥 Распаковка templates..."
send "sudo mkdir -p core/templates/chef\r"
expect "administrator@*"
send "sudo tar xzf /tmp/chef_templates.tar.gz -C core/templates/\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data core/templates/\r"
expect "administrator@*"
send "sudo chmod -R 755 core/templates/\r"
expect "administrator@*"
puts "✅ Templates распакованы"

# Проверяем миграцию
puts "\n🔍 Проверка миграции..."
send "ls -la core/migrations/0017_dishttk.py\r"
expect "administrator@*"

# Применяем миграцию
puts "\n🔄 Применение миграции..."
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
}

# Перезапускаем сервис
puts "\n🔄 Перезапуск backend..."
send "sudo systemctl restart estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Backend перезапущен"
    }
}

send "sleep 2\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

send "exit\r"
expect eof

# Очистка
spawn bash -c "rm /tmp/chef_templates.tar.gz"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "=========================================="

