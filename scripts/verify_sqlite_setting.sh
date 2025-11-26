#!/usr/bin/expect -f

# Проверка настройки USE_SQLITE

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю .env файл..."
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

sleep 2

puts "🧪 Тестирую чтение переменной USE_SQLITE в Django..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 -c \"import os; os.environ.setdefault(\\\"DJANGO_SETTINGS_MODULE\\\", \\\"este_nomada.settings\\\"); import django; django.setup(); from django.conf import settings; print(\\\"USE_SQLITE:\\\", hasattr(settings, \\\"USE_SQLITE\\\") and settings.USE_SQLITE); print(\\\"DATABASES ENGINE:\\\", settings.DATABASES[\\\"default\\\"][\\\"ENGINE\\\"])\"' 2>&1"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

