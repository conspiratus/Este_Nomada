#!/usr/bin/expect -f

# Скрипт для применения миграции orders_display_statuses на сервере

set timeout 30

# Параметры подключения (замените на свои)
set server "ваш_сервер"
set user "ваш_пользователь"
set password "ваш_пароль"
set db_name "ваша_база_данных"

spawn ssh $user@$server

expect {
    "password:" {
        send "$password\r"
    }
    "yes/no" {
        send "yes\r"
        expect "password:"
        send "$password\r"
    }
}

expect "$ "

# Переходим в директорию проекта
send "cd /var/www/estenomada/backend\r"
expect "$ "

# Применяем SQL скрипт
send "mysql -u root -p$password $db_name < core/migrations/apply_orders_display_statuses_manually.sql\r"
expect "$ "

# Или применяем через Django migrate (если есть доступ)
# send "source venv/bin/activate\r"
# expect "$ "
# send "python manage.py migrate core 0048\r"
# expect "$ "

send "exit\r"
expect eof

