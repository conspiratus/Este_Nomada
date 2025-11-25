#!/usr/bin/expect -f

# Тестирование доступа к /chef/

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Тестирование доступа к /chef/"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"

# Проверяем конфигурацию
puts "\n🔍 Проверка конфигурации nginx..."
send "sudo grep -B 2 -A 10 'location.*chef' /etc/nginx/sites-available/estenomada | head -25\r"
expect "administrator@*"

# Проверяем доступность Django напрямую
puts "\n🔍 Проверка Django /chef/..."
send "curl -s http://localhost:8000/chef/ | head -20\r"
expect "administrator@*"

# Проверяем через nginx без SSL
puts "\n🔍 Проверка через nginx (HTTP)..."
send "curl -s -k http://localhost/en/chef 2>&1 | head -20\r"
expect "administrator@*"

# Проверяем логи nginx
puts "\n🔍 Последние записи в логах nginx..."
send "sudo tail -5 /var/log/nginx/estenomada_access.log | grep chef\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Проверка завершена"
puts "=========================================="

