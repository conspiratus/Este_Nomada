#!/usr/bin/expect -f

# Финальная проверка интерфейса повара

set timeout 120
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Финальная проверка интерфейса повара"
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

# Проверяем установлен ли markdown
puts "\n🔍 Проверка markdown..."
send "source venv/bin/activate && python -c 'import markdown; print(\"✅ markdown установлен\")' 2>&1\r"
expect "administrator@*"

# Проверяем доступность /chef/login/
puts "\n🔍 Проверка /chef/login/..."
send "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/chef/login/\r"
expect "administrator@*"

# Проверяем логи на ошибки
puts "\n🔍 Проверка последних ошибок в логах..."
send "sudo tail -20 logs/error.log | grep -i error | tail -5\r"
expect "administrator@*"

# Проверяем, что views импортируются
puts "\n🔍 Проверка импорта views..."
send "source venv/bin/activate && python manage.py shell -c \"from core.views import chef_dashboard; print('✅ chef_dashboard импортирована')\" 2>&1\r"
expect "administrator@*"

# Проверяем nginx location
puts "\n🔍 Проверка nginx location для /chef/..."
send "sudo grep -A 10 'location /chef' /etc/nginx/sites-available/estenomada\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Проверка завершена"
puts "Проверь: https://estenomada.es/chef/"
puts "=========================================="

