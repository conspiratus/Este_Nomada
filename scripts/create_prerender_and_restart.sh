#!/usr/bin/expect -f

# Создание prerender-manifest.json и перезапуск

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔧 Создаю prerender-manifest.json..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo tee .next/prerender-manifest.json > /dev/null << 'EOF'
{
  \"version\": 4,
  \"routes\": {},
  \"dynamicRoutes\": {},
  \"notFoundRoutes\": [],
  \"preview\": {
    \"previewModeId\": \"\",
    \"previewModeSigningKey\": \"\",
    \"previewModeEncryptionKey\": \"\"
  }
}
EOF
sudo chown www-data:www-data .next/prerender-manifest.json && echo '✅ prerender-manifest.json создан'"

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

puts "🚀 Перезапускаю сервис..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 3 && sudo systemctl is-active estenomada-frontend && echo '✅ Сервис запущен'"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Готово"

