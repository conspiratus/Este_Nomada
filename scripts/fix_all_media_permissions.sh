#!/usr/bin/expect -f

# Исправление прав доступа для всей директории media

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Исправление прав доступа для media"
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

# Устанавливаем права на всю директорию media
puts "\n🔐 Установка прав доступа на media..."
send "sudo chown -R www-data:www-data media/\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Права установлены"
    }
}

send "sudo chmod -R 755 media/\r"
expect "administrator@*"

# Проверяем права
puts "\n🔍 Проверка прав доступа..."
send "ls -la media/ | head -10\r"
expect "administrator@*"

# Проверяем, что www-data может создавать файлы в ttk
puts "\n🔍 Проверка возможности записи в ttk..."
send "sudo -u www-data touch media/ttk/test2.txt 2>&1 && sudo rm media/ttk/test2.txt && echo '✅ Запись в ttk работает' || echo '❌ Ошибка записи'\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Теперь можно загружать ТТК файлы в админке"
puts "=========================================="

