#!/usr/bin/expect -f

# Скрипт для деплоя изменений футера с поддержкой HTML в заголовке

set timeout 300
set password "Drozdofil12345!"
set host "ssh.czjey8yl0.service.one"
set user "czjey8yl0_ssh"
set remote_dir "/customers/d/9/4/czjey8yl0/webroots/17a5d75c"

puts "📤 Загружаю компонент Footer..."
spawn scp -P 22 -o StrictHostKeyChecking=no components/Footer.tsx ${user}@${host}:${remote_dir}/components/Footer.tsx

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

puts "📤 Загружаю модель FooterSection..."
spawn scp -P 22 -o StrictHostKeyChecking=no backend/core/models.py ${user}@${host}:${remote_dir}/backend/core/models.py

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

puts "🔄 Применяю миграции Django..."
spawn ssh -p 22 -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir}/backend && source venv/bin/activate 2>/dev/null || python3 -m venv venv && source venv/bin/activate && pip install -q -r requirements.txt && python manage.py makemigrations --noinput && python manage.py migrate --noinput"

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
        puts "✅ Миграции применены"
    }
}

puts ""
puts "✅ Деплой завершён!"
puts "📋 Изменения:"
puts "   - Footer.tsx: заголовок теперь поддерживает HTML"
puts "   - models.py: добавлен help_text для поля title"
puts ""
puts "🌐 Проверь сайт: https://estenomada.es"


