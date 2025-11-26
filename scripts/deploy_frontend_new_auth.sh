#!/usr/bin/expect -f

# Деплой новой версии фронтенда (админка + auth) на прод-сервер

set timeout 900
set password "Jovi4AndMay2020!"
set host "85.190.102.101"
set user "administrator"
set project_dir "/var/www/estenomada"

# Утилита для ожидания password:
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

puts "\n📤 Загружаю обновлённые файлы фронтенда...\n"

# 1) lib/auth.ts
puts "1/9 lib/auth.ts"
spawn scp -o StrictHostKeyChecking=no lib/auth.ts $user@$host:/tmp/auth.ts
wait_password

# 2) middleware.ts
puts "2/9 middleware.ts"
spawn scp -o StrictHostKeyChecking=no middleware.ts $user@$host:/tmp/middleware.ts
wait_password

# 3) app/admin/page.tsx (страница логина)
puts "3/9 app/admin/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/page.tsx $user@$host:/tmp/admin_page.tsx
wait_password

# 4) app/admin/dashboard/page.tsx
puts "4/9 app/admin/dashboard/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/dashboard/page.tsx $user@$host:/tmp/admin_dashboard_page.tsx
wait_password

# 5) app/admin/menu/page.tsx
puts "5/9 app/admin/menu/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/menu/page.tsx $user@$host:/tmp/admin_menu_page.tsx
wait_password

# 6) app/admin/stories/page.tsx
puts "6/9 app/admin/stories/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/stories/page.tsx $user@$host:/tmp/admin_stories_page.tsx
wait_password

# 7) app/admin/settings/page.tsx
puts "7/9 app/admin/settings/page.tsx"
spawn scp -o StrictHostKeyChecking=no app/admin/settings/page.tsx $user@$host:/tmp/admin_settings_page.tsx
wait_password

# 8) app/api/admin/auth/login/route.ts
puts "8/9 app/api/admin/auth/login/route.ts"
spawn scp -o StrictHostKeyChecking=no app/api/admin/auth/login/route.ts $user@$host:/tmp/admin_auth_login_route.ts
wait_password

# 9) app/api/admin/auth/check/route.ts
puts "9/9 app/api/admin/auth/check/route.ts"
spawn scp -o StrictHostKeyChecking=no app/api/admin/auth/check/route.ts $user@$host:/tmp/admin_auth_check_route.ts
wait_password

# 10) app/api/admin/menu/[id]/translations/route.ts
puts "10/10 app/api/admin/menu/[id]/translations/route.ts"
spawn scp -o StrictHostKeyChecking=no "app/api/admin/menu/[id]/translations/route.ts" $user@$host:/tmp/admin_menu_translations_route.ts
wait_password

sleep 2

puts "\n🔧 Копирую файлы в рабочую директорию с sudo...\n"
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
  sudo cp /tmp/admin_menu_translations_route.ts $project_dir/app/api/admin/menu/[id]/translations/route.ts && \
  sudo chown -R www-data:www-data $project_dir/app $project_dir/lib $project_dir/middleware.ts && \
  echo '✅ Файлы скопированы'
"
wait_password

sleep 2

puts "\n🧹 Очищаю старую сборку .next...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo rm -rf .next && echo '✅ .next удалён'"
wait_password

sleep 2

puts "\n🔨 Пересобираю проект (npm run build)...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "cd $project_dir && sudo -u www-data NODE_ENV=production npm run build 2>&1 | tail -40"
wait_password

sleep 2

puts "\n🔍 Проверяю/создаю prerender-manifest.json при необходимости...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "\
  if [ ! -f $project_dir/.next/prerender-manifest.json ]; then \
    echo 'Файл отсутствует, создаю минимальный...'; \
    sudo tee $project_dir/.next/prerender-manifest.json > /dev/null << 'JSON' \
{\n  \"version\": 4,\n  \"routes\": {},\n  \"dynamicRoutes\": {},\n  \"notFoundRoutes\": [],\n  \"preview\": {\n    \"previewModeId\": \"\",\n    \"previewModeSigningKey\": \"\",\n    \"previewModeEncryptionKey\": \"\"\n  }\n}\nJSON\n    sudo chown www-data:www-data $project_dir/.next/prerender-manifest.json; \
  fi && \
  echo '✅ prerender-manifest.json в порядке'
"
wait_password

sleep 2

puts "\n🚀 Перезапускаю сервис фронтенда...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "sudo systemctl restart estenomada-frontend && sleep 5 && sudo systemctl status estenomada-frontend --no-pager | head -12"
wait_password

sleep 2

puts "\n🧪 Быстрый тест: /api/admin/auth/check (ожидаем 401 без куки)...\n"
spawn ssh -o StrictHostKeyChecking=no $user@$host "curl -sI https://estenomada.es/api/admin/auth/check 2>&1 | head -5"
wait_password

puts "\n✅ Деплой фронтенда завершён.\n"
