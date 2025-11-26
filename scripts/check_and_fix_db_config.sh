#!/usr/bin/expect -f

# Проверка и исправление конфигурации базы данных

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю настройки базы данных в .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo grep -E '^DB_|^USE_SQLITE' .env 2>/dev/null | sed 's/PASSWORD=.*/PASSWORD=***/' || echo 'Настройки БД не найдены'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "🔍 Проверяю подключение к MySQL..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u czjey8yl0_estenomada -p'$(sudo grep DB_PASSWORD $backend_dir/.env 2>/dev/null | cut -d= -f2)' -e 'SELECT 1' 2>&1 | head -5 || echo 'Ошибка подключения'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

sleep 2

puts "💡 Рекомендация: Проверь настройки базы данных в .env файле Django"
puts "   Нужно убедиться, что:"
puts "   - DB_PASSWORD правильный"
puts "   - DB_USER имеет доступ к базе данных"
puts "   - USE_SQLITE=False для production"

puts "✅ Проверка завершена"

