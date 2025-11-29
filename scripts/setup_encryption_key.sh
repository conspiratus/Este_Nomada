#!/usr/bin/expect -f

# Установка ENCRYPTION_KEY и применение миграции 0032_encrypt_personal_data

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"
set encryption_key "OY09xayMADRQFejKu7IWJFkEcajeqD372_JDIZ59EnU="

puts "🔐 Устанавливаю ENCRYPTION_KEY в .env.production..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo bash -c 'if grep -q \"^ENCRYPTION_KEY=\" .env.production 2>/dev/null; then
    sudo sed -i \"s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$encryption_key|\" .env.production
    echo \"✅ ENCRYPTION_KEY обновлен\"
else
    echo \"ENCRYPTION_KEY=$encryption_key\" | sudo tee -a .env.production > /dev/null
    echo \"✅ ENCRYPTION_KEY добавлен\"
fi'"

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

puts "🔍 Проверяю, что ENCRYPTION_KEY установлен..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo grep '^ENCRYPTION_KEY=' .env.production | sed 's/=.*/=***/'"

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

puts "🗄️  Применяю миграцию 0032_encrypt_personal_data..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py migrate core 0032_encrypt_personal_data --noinput'"

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

puts "📋 Проверяю статус миграций..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python manage.py showmigrations core | tail -5'"

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

puts "🔄 Перезапускаю backend сервис..."

spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-backend && sleep 3 && sudo systemctl status estenomada-backend --no-pager | head -10"

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
puts "✅ Готово! ENCRYPTION_KEY установлен и миграция применена."

