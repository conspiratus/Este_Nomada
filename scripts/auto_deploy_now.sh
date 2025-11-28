#!/usr/bin/expect -f
# Автоматический деплой на production с использованием expect

set timeout 600
set server "czjey8yl0_ssh@ssh.czjey8yl0.service.one"
set password "Drozdofil12345!"
set remote_dir "/customers/d/9/4/czjey8yl0/webroots/17a5d75c"

puts "🚀 Начинаем автоматический деплой на production..."
puts ""

# Подключаемся и выполняем деплой
spawn ssh -p 22 -o StrictHostKeyChecking=no $server "cd $remote_dir && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart && chmod +x scripts/deploy_all_to_prod.sh && ./scripts/deploy_all_to_prod.sh"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        exp_continue
    }
    eof {
        catch wait result
        exit [lindex $result 3]
    }
}

interact

