#!/usr/bin/expect -f

# Установка markdown для Django

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Установка markdown"
puts "=========================================="

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

# Устанавливаем markdown
puts "\n📦 Установка markdown..."
send "source venv/bin/activate && pip install markdown\r"
expect {
    "administrator@*" {
        puts "✅ markdown установлен"
    }
    timeout {
        puts "⚠️  Timeout"
    }
}

# Проверяем установку
puts "\n🔍 Проверка установки..."
send "python -c 'import markdown; print(\"✅ markdown установлен и работает\")' 2>&1\r"
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

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/chef/"
puts "=========================================="

