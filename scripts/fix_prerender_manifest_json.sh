#!/usr/bin/expect -f

# Исправление prerender-manifest.json

set timeout 60
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "🔧 Исправляю prerender-manifest.json..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $remote_dir && sudo tee .next/prerender-manifest.json > /dev/null << 'PRERENDER_EOF'
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
PRERENDER_EOF
sudo chown www-data:www-data .next/prerender-manifest.json && sudo chmod 644 .next/prerender-manifest.json && echo '✅ prerender-manifest.json исправлен' && echo '' && echo 'Проверка валидности JSON:' && cat .next/prerender-manifest.json | python3 -m json.tool > /dev/null && echo '✅ JSON валиден' || echo '❌ JSON невалиден'"

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
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -12"

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

puts "🧪 Тестирую доступность Next.js..."
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI http://localhost:3000 2>&1 | head -5"

expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof { 
        puts ""
    }
}

puts "✅ Исправление завершено"

