#!/usr/bin/expect -f

# Исправление прав доступа для media/ttk

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Исправление прав доступа для media/ttk"
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

# Создаём директорию media/ttk
puts "\n📁 Создание директории media/ttk..."
send "sudo mkdir -p media/ttk\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Директория создана"
    }
}

# Устанавливаем права
puts "\n🔐 Установка прав доступа..."
send "sudo chown -R www-data:www-data media/ttk\r"
expect "administrator@*"
send "sudo chmod -R 755 media/ttk\r"
expect "administrator@*"

# Проверяем права
puts "\n🔍 Проверка прав доступа..."
send "ls -la media/ | grep ttk\r"
expect "administrator@*"

# Проверяем, что www-data может писать
puts "\n🔍 Проверка возможности записи..."
send "sudo -u www-data touch media/ttk/test.txt 2>&1 && sudo rm media/ttk/test.txt && echo '✅ Запись работает' || echo '❌ Ошибка записи'\r"
expect "administrator@*"

# Проверяем права на всю директорию media
puts "\n🔍 Проверка прав на media..."
send "ls -la media/ | head -5\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Попробуй загрузить ТТК файл в админке"
puts "=========================================="

