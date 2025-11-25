#!/usr/bin/expect -f

# Проверка ошибки при логине в Django

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"

puts "🔍 Проверяю последние ошибки Django при логине..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo journalctl -u estenomada-backend -n 100 --no-pager | grep -A 20 -i 'login\|auth\|error\|exception\|traceback' | tail -50"

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

puts "🔍 Проверяю настройки базы данных..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd /var/www/estenomada/backend && sudo grep -E '^DB_|^USE_SQLITE' .env 2>/dev/null | sed 's/PASSWORD=.*/PASSWORD=***/' || echo 'Настройки БД не найдены'"

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

puts "🧪 Тестирую подключение к MySQL..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd /var/www/estenomada/backend && sudo -u www-data python3 manage.py check --database default 2>&1 | head -20"

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

puts "🔍 Проверяю статус сервиса backend..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl status estenomada-backend --no-pager | head -20"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

