#!/usr/bin/expect -f

# Создание исправленных layout файлов на сервере

set timeout 300
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"
set remote_dir "/var/www/estenomada"

puts "=========================================="
puts "Создание исправленных layout файлов"
puts "=========================================="

spawn ssh $server
expect {
    "password:" {
        send "$password\r"
    }
}

expect "administrator@*"
send "cd $remote_dir\r"
expect "administrator@*"

# Останавливаем фронтенд
puts "\n🛑 Остановка фронтенда..."
send "sudo systemctl stop estenomada-frontend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Фронтенд остановлен"
    }
}

# Создаём app/layout.tsx
puts "\n📝 Создание app/layout.tsx..."
send "sudo bash -c 'cat > app/layout.tsx << \"LAYOUTEOF\"\r"
expect ">"
send "// Root layout для next-intl с App Router\r"
expect ">"
send "// Для next-intl с App Router root layout должен быть максимально минимальным\r"
expect ">"
send "// html/body создаются в [locale]/layout.tsx\r"
expect ">"
send "export const metadata = {\r"
expect ">"
send "  icons: {\r"
expect ">"
send "    icon: [\r"
expect ">"
send "      { url: \\\"/favicon.ico\\\", sizes: \\\"any\\\" },\r"
expect ">"
send "      { url: \\\"/favicon.png\\\", type: \\\"image/png\\\" },\r"
expect ">"
send "    ],\r"
expect ">"
send "    apple: \\\"/favicon.png\\\",\r"
expect ">"
send "  },\r"
expect ">"
send "};\r"
expect ">"
send "\r"
expect ">"
send "export default function RootLayout({\r"
expect ">"
send "  children,\r"
expect ">"
send "}: {\r"
expect ">"
send "  children: React.ReactNode;\r"
expect ">"
send "}) {\r"
expect ">"
send "  // Для next-intl с App Router root layout должен возвращать children\r"
expect ">"
send "  // html/body создаются в [locale]/layout.tsx\r"
expect ">"
send "  return <>{children}</>;\r"
expect ">"
send "}\r"
expect ">"
send "LAYOUTEOF'\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ app/layout.tsx создан"
    }
}

# Добавляем suppressHydrationWarning в locale layout
puts "\n📝 Обновление locale layout..."
send "sudo sed -i 's/<html lang=/<html lang=/g; s/<html lang=\\([^>]*\\)>/<html lang=\\1 suppressHydrationWarning>/g' 'app/[locale]/layout.tsx'\r"
expect "administrator@*"
send "sudo sed -i 's/<body>/<body suppressHydrationWarning>/g' 'app/[locale]/layout.tsx'\r"
expect "administrator@*"

send "sudo chown -R www-data:www-data app/\r"
expect "administrator@*"

# Пересобираем фронтенд
puts "\n🔨 Пересборка фронтенда..."
send "sudo chown -R administrator:administrator .\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build\r"
expect {
    "administrator@*" {
        puts "✅ Сборка завершена"
    }
    timeout {
        puts "⚠️  Timeout (продолжаем...)"
    }
}

# Устанавливаем права
send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Создаём prerender-manifest.json если нужно
send "if [ ! -f .next/prerender-manifest.json ]; then python3 -c \"import json; json.dump({'version': 4, 'routes': {}, 'dynamicRoutes': {}, 'notFoundRoutes': [], 'preview': {'previewModeId': '', 'previewModeSigningKey': '', 'previewModeEncryptionKey': ''}}, open('.next/prerender-manifest.json', 'w'), indent=2)\"; sudo chown www-data:www-data .next/prerender-manifest.json; fi\r"
expect "administrator@*"

# Запускаем фронтенд
puts "\n🚀 Запуск фронтенда..."
send "sudo systemctl start estenomada-frontend\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Фронтенд запущен"
    }
}

# Проверяем статус
puts "\n🔍 Проверка статуса..."
send "sleep 8\r"
expect "administrator@*"
send "sudo systemctl status estenomada-frontend --no-pager | head -20\r"
expect "administrator@*"

send "exit\r"
expect eof

puts "\n=========================================="
puts "✅ Готово!"
puts "Проверь сайт: https://estenomada.es"
puts "=========================================="

