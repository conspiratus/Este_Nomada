#!/usr/bin/expect -f

# Обновление шаблона ttk_view.html

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set backend_dir "/var/www/estenomada/backend"

puts "=========================================="
puts "Обновление шаблона ttk_view.html"
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

# Распаковываем шаблоны
puts "\n📥 Распаковка шаблонов..."
send "sudo tar -xzf /tmp/chef_templates.tar.gz -C core/templates/ --overwrite\r"
expect "administrator@*"
send "sudo chown -R www-data:www-data core/templates/chef\r"
expect "administrator@*"

# Проверяем шаблон
puts "\n🔍 Проверка шаблона..."
send "grep -n 'html_content' core/templates/chef/ttk_view.html\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь: https://estenomada.es/chef/"
puts "=========================================="

