#!/usr/bin/expect -f

# Загрузка URL файлов для chef интерфейса

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Загрузка URL файлов для chef"
puts "=========================================="

# Загружаем core/urls.py
puts "\n📤 Загрузка core/urls.py..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/core/urls.py $server:/tmp/core_urls.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Загружаем este_nomada/urls.py
puts "\n📤 Загрузка este_nomada/urls.py..."
spawn scp /Users/conspiratus/Projects/Este_Nomada/backend/este_nomada/urls.py $server:/tmp/este_nomada_urls.py
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}

# Подключаемся
spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $backend_dir\r"
expect "administrator@*"

# Останавливаем Django
puts "\n🛑 Остановка Django..."
send "sudo systemctl stop estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django остановлен"
    }
}

# Копируем файлы
puts "\n📥 Копирование файлов..."
send "sudo mkdir -p core\r"
expect "administrator@*"
send "sudo cp /tmp/core_urls.py core/urls.py\r"
expect "administrator@*"
send "sudo cp /tmp/este_nomada_urls.py este_nomada/urls.py\r"
expect "administrator@*"
send "sudo chown www-data:www-data core/urls.py este_nomada/urls.py\r"
expect "administrator@*"

# Проверяем файлы
puts "\n🔍 Проверка файлов..."
send "grep -n 'chef' este_nomada/urls.py\r"
expect "administrator@*"
send "head -10 core/urls.py\r"
expect "administrator@*"

# Запускаем Django
puts "\n🚀 Запуск Django..."
send "sudo systemctl start estenomada-backend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Django запущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

# Проверяем доступность
puts "\n🔍 Проверка доступности /chef/..."
send "curl -I http://localhost:8000/chef/ 2>&1 | head -5\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Теперь нужно добавить location /chef/ в nginx"
puts "=========================================="

