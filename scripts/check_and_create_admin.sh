#!/usr/bin/expect -f

# Проверка и создание администратора

set timeout 120
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю пользователей в базе данных..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SELECT id, username, email, is_staff, is_superuser FROM auth_user;' 2>&1 | grep -v 'Warning'"

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

puts "🔧 Создаю суперпользователя admin..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 manage.py shell << \"PYTHON\"
from django.contrib.auth.models import User
import sys

username = \"admin\"
email = \"admin@estenomada.es\"
password = \"admin123\"

try:
    user = User.objects.get(username=username)
    print(f\"Пользователь {username} уже существует\")
    user.set_password(password)
    user.is_staff = True
    user.is_superuser = True
    user.is_active = True
    user.save()
    print(f\"Пароль пользователя {username} обновлен\")
except User.DoesNotExist:
    user = User.objects.create_superuser(username, email, password)
    print(f\"Создан суперпользователь {username}\")
except Exception as e:
    print(f\"Ошибка: {e}\")
    sys.exit(1)
PYTHON
' 2>&1"

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

puts "🔍 Проверяю созданного пользователя..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "mysql -u u_estenomada -p'Jovi4AndMay2020!' -h localhost db_estenomada -e 'SELECT id, username, email, is_staff, is_superuser, is_active FROM auth_user WHERE username=\"admin\";' 2>&1 | grep -v 'Warning'"

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

puts "🧪 Тестирую логин с новыми учетными данными..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -s -X POST 'https://estenomada.es/api/auth/login/' -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin123\"}' | head -10"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

