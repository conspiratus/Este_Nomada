#!/usr/bin/expect -f

# Упрощённый деплой новой версии фронтенда (включая translations route)

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

puts "\n📤 Загружаю файлы...\n"

# lib/auth.ts
spawn scp -o StrictHostKeyChecking=no lib/auth.ts $user@$host:/tmp/auth.ts
wait_password

# middleware.ts
spawn scp -o StrictHostKeyChecking=no middleware.ts $user@$host:/tmp/middleware.ts
wait_password

# admin pages
spawn scp -o StrictHostKeyChecking=no app/admin/page.tsx $user@$host:/tmp/admin_page.tsx
wait_password
spawn scp -o StrictHostKeyChecking=no app/admin/dashboard/page.tsx $user@$host:/tmp/admin_dashboard_page.tsx
wait_password
spawn scp -o StrictHostKeyChecking=no app/admin/menu/page.tsx $user@$host:/tmp/admin_menu_page.tsx
wait_password
spawn scp -o StrictHostKeyChecking=no app/admin/stories/page.tsx $user@$host:/tmp/admin_stories_page.tsx
wait_password
spawn scp -o StrictHostKeyChecking=no app/admin/settings/page.tsx $user@$host:/tmp/admin_settings_page.tsx
wait_password

# admin auth routes
spawn scp -o StrictHostKeyChecking=no app/api/admin/auth/login/route.ts $user@$host:/tmp/admin_auth_login_route.ts
wait_password
spawn scp -o StrictHostKeyChecking=no app/api/admin/auth/check/route.ts $user@$host:/tmp/admin_auth_check_route.ts
wait_password

# translations route (экранируем [id])
spawn scp -o StrictHostKeyChecking=no "app/api/admin/menu/\[id]/translations/route.ts" $user@$host:/tmp/admin_menu_translations_route.ts
wait_password

sleep 2

puts "\n🔧 Копирую файлы в проект...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "\
  sudo cp /tmp/auth.ts $project_dir/lib/auth.ts && \
  sudo cp /tmp/middleware.ts $project_dir/middleware.ts && \
  sudo cp /tmp/admin_page.tsx $project_dir/app/admin/page.tsx && \
  sudo cp /tmp/admin_dashboard_page.tsx $project_dir/app/admin/dashboard/page.tsx && \
  sudo cp /tmp/admin_menu_page.tsx $project_dir/app/admin/menu/page.tsx && \
  sudo cp /tmp/admin_stories_page.tsx $project_dir/app/admin/stories/page.tsx && \
  sudo cp /tmp/admin_settings_page.tsx $project_dir/app/admin/settings/page.tsx && \
  sudo cp /tmp/admin_auth_login_route.ts $project_dir/app/api/admin/auth/login/route.ts && \
  sudo cp /tmp/admin_auth_check_route.ts $project_dir/app/api/admin/auth/check/route.ts && \
  sudo cp /tmp/admin_menu_translations_route.ts $project_dir/app/api/admin/menu/\[id]/translations/route.ts && \
  sudo chown -R www-data:www-data $project_dir/app $project_dir/lib $project_dir/middleware.ts && \
  echo '✅ Файлы скопированы'
"
wait_password

sleep 2

puts "\n🧹 Очищаю .next и пересобираю...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo rm -rf .next && echo '✅ .next удалён' && sudo -u www-data NODE_ENV=production npm run build 2>&1 | tail -40"
wait_password

sleep 2

puts "\n🚀 Перезапускаю frontend-сервис...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -12"
wait_password

sleep 2

puts "\n🧪 Проверка /api/admin/auth/check...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/api/admin/auth/check 2>&1 | head -5"
wait_password

puts "\n✅ deploy_frontend_new_auth_step2 завершён.\n"
