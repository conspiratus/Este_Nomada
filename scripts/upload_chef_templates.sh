#!/usr/bin/expect -f

# Загрузка шаблонов для chef интерфейса

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Загрузка шаблонов для chef"
puts "=========================================="

# Создаём архив с шаблонами
puts "\n📦 Создание архива с шаблонами..."
spawn tar -czf /tmp/chef_templates.tar.gz -C /Users/conspiratus/Projects/Este_Nomada/backend/core/templates chef/
expect {
    eof
}

# Загружаем архив
puts "\n📤 Загрузка архива..."
spawn scp /tmp/chef_templates.tar.gz $server:/tmp/chef_templates.tar.gz
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

# Распаковываем шаблоны
puts "\n📥 Распаковка шаблонов..."
send "sudo mkdir -p core/templates/chef\r"
expect "administrator@*"
send "sudo tar -xzf /tmp/chef_templates.tar.gz -C core/templates/\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data core/templates/chef\r"
expect "administrator@*"

# Проверяем шаблоны
puts "\n🔍 Проверка шаблонов..."
send "ls -la core/templates/chef/\r"
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
send "sleep 5\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager | head -10\r"
expect "administrator@*"

# Проверяем доступность
puts "\n🔍 Проверка доступности /chef/..."
send "curl -s http://localhost:8000/chef/ 2>&1 | head -30\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/chef/"
puts "=========================================="

