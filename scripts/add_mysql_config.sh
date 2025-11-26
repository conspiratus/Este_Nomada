#!/usr/bin/expect -f

# Добавление настроек MySQL в .env

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔧 Добавляю настройки MySQL в .env..."
puts "⚠️  ВАЖНО: Нужно будет указать правильный пароль базы данных!"
puts ""

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'cat >> .env << EOF

# Database (MySQL)
DB_NAME=czjey8yl0_estenomada
DB_USER=czjey8yl0_estenomada
DB_PASSWORD=CHANGE_ME_PASSWORD
DB_HOST=localhost
DB_PORT=3306
EOF
echo \"✅ Настройки MySQL добавлены (пароль нужно заменить!)\"'"

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

puts "🔍 Проверяю обновленный .env..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env | grep -E 'USE_SQLITE|DB_'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

