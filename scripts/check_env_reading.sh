#!/usr/bin/expect -f

# Проверка чтения .env файла

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set backend_dir "/var/www/estenomada/backend"

puts "🔍 Проверяю полный .env файл..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo cat .env"

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

puts "🔍 Проверяю, где находится .env файл относительно BASE_DIR..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $backend_dir && sudo -u www-data bash -c 'source venv/bin/activate && python3 -c \"import os; from pathlib import Path; BASE_DIR = Path(\\\"/var/www/estenomada/backend\\\").resolve(); env_path = BASE_DIR / \\\".env\\\"; print(\\\"BASE_DIR:\\\", BASE_DIR); print(\\\".env path:\\\", env_path); print(\\\"Exists:\\\", env_path.exists())\"'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

