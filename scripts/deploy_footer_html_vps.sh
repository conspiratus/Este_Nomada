#!/usr/bin/expect -f

# Скрипт для деплоя изменений футера с поддержкой HTML в заголовке на VPS

set timeout 300
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "📤 Загружаю компонент Footer во временную директорию..."
spawn scp -o StrictHostKeyChecking=no components/Footer.tsx ${user}@${host}:/tmp/Footer.tsx

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ Footer.tsx загружен"
    }
}

sleep 2

puts "📤 Загружаю модель FooterSection во временную директорию..."
spawn scp -o StrictHostKeyChecking=no backend/core/models.py ${user}@${host}:/tmp/models.py

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts "✅ models.py загружен"
    }
}

sleep 2

puts "📋 Копирую файлы в проект с правильными правами..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "sudo cp /tmp/Footer.tsx ${remote_dir}/components/Footer.tsx && sudo cp /tmp/models.py ${remote_dir}/backend/core/models.py && sudo chown www-data:www-data ${remote_dir}/components/Footer.tsx ${remote_dir}/backend/core/models.py && echo '✅ Файлы скопированы'"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts ""
    }
}

sleep 2

puts "🔄 Применяю миграции Django..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate && python manage.py makemigrations --noinput && python manage.py migrate --noinput && echo '✅ Миграции применены'"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts ""
    }
}

sleep 2

puts "🔄 Перезапускаю фронтенд..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "sudo systemctl restart estenomada-frontend && sleep 3 && sudo systemctl is-active estenomada-frontend && echo '✅ Фронтенд перезапущен'"

expect {
    "password:" {
        send "${password}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        puts ""
    }
}

puts ""
puts "✅ Деплой завершён!"
puts "📋 Изменения:"
puts "   - Footer.tsx: заголовок теперь поддерживает HTML"
puts "   - models.py: добавлен help_text для поля title"
puts ""
puts "🌐 Проверь сайт: https://estenomada.es"
