#!/usr/bin/expect -f

# Исправляем права и пересобираем фронтенд (build под administrator, затем .next -> www-data)

set timeout 900
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

proc wait_password {} {
  expect {
    "password:" {
      send "$::password\r"
      exp_continue
    }
    eof {
      puts ""
    }
  }
}

puts "\n🔧 Исправляю права и пересобираю фронтенд...\n"

spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && \
  sudo chown -R $user:$user .next 2>/dev/null || true && \
  sudo rm -rf .next && echo '✅ .next удалён' && \
  NODE_ENV=production npm run build 2>&1 | tail -40 && \
  sudo chown -R www-data:www-data .next && echo '✅ .next принадлежит www-data'"

wait_password

sleep 2

puts "\n🚀 Перезапускаю сервис фронтенда...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -12"
wait_password

sleep 2

puts "\n🧪 Проверяю /api/admin/auth/check...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/api/admin/auth/check 2>&1 | head -5"
wait_password

puts "\n✅ fix_frontend_build_permissions завершён.\n"
