#!/usr/bin/expect -f

set timeout 30
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "Исправление прав доступа к SQLite..."

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"

# Показываем текущие права
puts "\n📋 Текущие права:"
send "ls -la db.sqlite3\r"
expect "administrator@*"
send "ls -ld .\r"
expect "administrator@*"

# Исправляем права - нужно чтобы www-data мог писать
puts "\n🔧 Исправление прав..."
send "sudo chown www-data:www-data db.sqlite3\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*"
}
send "sudo chmod 664 db.sqlite3\r"
expect "administrator@*"

# Директория тоже должна быть доступна для записи (для -journal файла)
send "sudo chown www-data:www-data /var/www/estenomada/backend\r"
expect "administrator@*"
send "sudo chmod 775 /var/www/estenomada/backend\r"
expect "administrator@*"

puts "\n✅ Новые права:"
send "ls -la db.sqlite3\r"
expect "administrator@*"
send "ls -ld .\r"
expect "administrator@*"

puts "\n🔄 Перезапуск backend..."
send "sudo systemctl restart estenomada-backend\r"
expect "administrator@*"
send "sleep 3\r"
expect "administrator@*"
send "sudo systemctl is-active estenomada-backend\r"
expect "administrator@*"

puts "\n✅ Готово! Теперь попробуй войти в админку."

send "exit\r"
expect eof


