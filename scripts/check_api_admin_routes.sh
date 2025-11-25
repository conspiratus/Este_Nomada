#!/usr/bin/expect -f

# Проверка API admin routes

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

puts "🔍 Проверяю существование файла check route..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "ls -la $project_dir/app/api/admin/auth/check/route.ts 2>&1"

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

puts "🔍 Проверяю структуру app/api..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "find $project_dir/app/api -type f -name '*.ts' | head -10"

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

puts "🔍 Проверяю, как Nginx обрабатывает /api/admin/..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo cat /etc/nginx/sites-enabled/estenomada.production.conf | grep -A 10 'location /api'"

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

puts "🧪 Тестирую /api/admin/auth/check напрямую через Next.js..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI http://localhost:3000/api/admin/auth/check 2>&1 | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

