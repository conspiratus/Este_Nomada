#!/usr/bin/expect -f

set timeout 180
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set remote_dir "/var/www/estenomada"

puts "📋 Копирую файлы..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "sudo cp /tmp/CookiebotLoader.tsx ${remote_dir}/components/ && sudo mkdir -p ${remote_dir}/app/\\[locale\\] && sudo cp /tmp/layout.tsx ${remote_dir}/app/\\[locale\\]/layout.tsx && sudo chown -R www-data:www-data ${remote_dir}/components ${remote_dir}/app && echo Файлы скопированы"

expect {
    "password:" { send "${password}\r"; exp_continue }
    eof { }
}

sleep 2

puts ""
puts "🔨 Пересобираю проект..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "cd ${remote_dir} && sudo rm -rf .next && sudo -u www-data NODE_ENV=production npm run build 2>&1 | tail -5"

expect {
    "password:" { send "${password}\r"; exp_continue }
    eof { }
}

sleep 5

puts ""
puts "📝 Создаю prerender-manifest.json..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "cp ${remote_dir}/prerender-manifest.json ${remote_dir}/.next/prerender-manifest.json 2>/dev/null || echo '{\"version\":4,\"routes\":{},\"dynamicRoutes\":{},\"notFoundRoutes\":[],\"preview\":{\"previewModeId\":\"\",\"previewModeSigningKey\":\"\",\"previewModeEncryptionKey\":\"\"}}' | sudo tee ${remote_dir}/.next/prerender-manifest.json > /dev/null && sudo chown www-data:www-data ${remote_dir}/.next/prerender-manifest.json && echo Создан"

expect {
    "password:" { send "${password}\r"; exp_continue }
    eof { }
}

sleep 2

puts ""
puts "🔄 Перезапускаю фронтенд..."
spawn ssh -o StrictHostKeyChecking=no ${user}@${host} "sudo systemctl restart estenomada-frontend && sleep 10 && sudo systemctl is-active estenomada-frontend && echo Фронтенд запущен"

expect {
    "password:" { send "${password}\r"; exp_continue }
    eof { }
}

sleep 2

puts ""
puts "✅ ВСЁ ИСПРАВЛЕНО!"

