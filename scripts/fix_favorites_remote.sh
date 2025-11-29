#!/usr/bin/expect -f

# Исправление таблицы favorites через Python скрипт

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "📤 Копирую скрипт на сервер..."

spawn scp -o StrictHostKeyChecking=no scripts/fix_favorites.py $user@$host:$backend_dir/

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

puts "🔧 Запускаю скрипт исправления..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 fix_favorites.py'"

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

puts "🧹 Удаляю временный скрипт..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo rm -f fix_favorites.py"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts ""
puts "✅ Исправление завершено!"

