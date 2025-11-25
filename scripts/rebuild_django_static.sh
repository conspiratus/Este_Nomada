#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Пересборка статики Django..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"

# Удаляем старую статику
send "sudo rm -rf staticfiles\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}

# Создаем директорию
send "sudo mkdir -p staticfiles\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data staticfiles\r"
expect "administrator@*"

# Собираем статику от имени www-data
puts "\n📦 Сборка статики..."
send "sudo -u www-data venv/bin/python3 manage.py collectstatic --noinput --clear\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Статика собрана"
    }
    timeout {
        puts "⚠️  Timeout"
    }
}

# Проверяем файлы
puts "\n🔍 Проверка файлов..."
send "ls -la staticfiles/admin/css/base.css\r"
expect "administrator@*"
send "ls staticfiles/admin/css/ | grep -v '^\\.'\r"
expect "administrator@*"

# Перезапускаем nginx для надежности
puts "\n🔄 Перезагрузка nginx..."
send "sudo systemctl reload nginx\r"
expect "administrator@*"

puts "\n✅ Готово!"

send "exit\r"
expect eof



