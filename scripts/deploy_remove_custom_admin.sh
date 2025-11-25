#!/usr/bin/expect -f

set timeout 60
set server "administrator@85.190.102.101"
set password "Jovi4AndMay2020!"

puts "=========================================="
puts "Удаление кастомной админки и настройка Django Admin"
puts "=========================================="

# Подключаемся к серверу
spawn ssh $server

expect {
    "password:" {
        send "$password\r"
    }
    timeout {
        puts "Timeout waiting for password prompt"
        exit 1
    }
}

expect "administrator@*" {
    puts "\n✅ Подключение установлено"
}

# Переходим в директорию проекта
send "cd /var/www/estenomada\r"
expect "administrator@*"

# Удаляем кастомную Next.js админку (если есть)
puts "\n🗑️  Удаление кастомной Next.js админки..."
send "rm -rf app/admin app/api/admin lib/auth.ts lib/admin-auth.ts\r"
expect "administrator@*"

# Обновляем middleware.ts
puts "\n📝 Обновление middleware.ts..."
send "cat > middleware.ts << 'EOF'\r"
expect ">"
send "import createMiddleware from 'next-intl/middleware';\r"
expect ">"
send "import { NextResponse } from 'next/server';\r"
expect ">"
send "import type { NextRequest } from 'next/server';\r"
expect ">"
send "import { locales, defaultLocale } from './lib/locales';\r"
expect ">"
send "\r"
expect ">"
send "const intlMiddleware = createMiddleware({\r"
expect ">"
send "  locales,\r"
expect ">"
send "  defaultLocale,\r"
expect ">"
send "  localePrefix: 'always',\r"
expect ">"
send "  localeDetection: true\r"
expect ">"
send "});\r"
expect ">"
send "\r"
expect ">"
send "export function middleware(request: NextRequest) {\r"
expect ">"
send "  const { pathname } = request.nextUrl;\r"
expect ">"
send "\r"
expect ">"
send "  if (\r"
expect ">"
send "    pathname.startsWith('/_next') ||\r"
expect ">"
send "    pathname.startsWith('/api') ||\r"
expect ">"
send "    pathname.startsWith('/favicon') ||\r"
expect ">"
send "    pathname.startsWith('/icon') ||\r"
expect ">"
send "    pathname.match(/\\.(ico|png|jpg|jpeg|gif|svg|webp|woff|woff2|ttf|eot|css|js|json)\$/i)\r"
expect ">"
send "  ) {\r"
expect ">"
send "    return NextResponse.next();\r"
expect ">"
send "  }\r"
expect ">"
send "\r"
expect ">"
send "  const savedLocale = request.cookies.get('NEXT_LOCALE')?.value;\r"
expect ">"
send "  if (savedLocale && locales.includes(savedLocale as any)) {\r"
expect ">"
send "    if (pathname === '/' || pathname === '') {\r"
expect ">"
send "      const url = request.nextUrl.clone();\r"
expect ">"
send "      url.pathname = \`/\${savedLocale}\`;\r"
expect ">"
send "      return NextResponse.redirect(url);\r"
expect ">"
send "    }\r"
expect ">"
send "  }\r"
expect ">"
send "\r"
expect ">"
send "  const response = intlMiddleware(request);\r"
expect ">"
send "  \r"
expect ">"
send "  const locale = request.nextUrl.pathname.split('/')[1];\r"
expect ">"
send "  if (locales.includes(locale as any)) {\r"
expect ">"
send "    response.cookies.set('NEXT_LOCALE', locale, {\r"
expect ">"
send "      path: '/',\r"
expect ">"
send "      maxAge: 60 * 60 * 24 * 365,\r"
expect ">"
send "      sameSite: 'lax'\r"
expect ">"
send "    });\r"
expect ">"
send "  }\r"
expect ">"
send "  \r"
expect ">"
send "  return response;\r"
expect ">"
send "}\r"
expect ">"
send "\r"
expect ">"
send "export const config = {\r"
expect ">"
send "  matcher: [\r"
expect ">"
send "    '/((?!api|_next|_vercel|.*\\\\..*).*)'\r"
expect ">"
send "  ],\r"
expect ">"
send "};\r"
expect ">"
send "EOF\r"
expect "administrator@*"
puts "✅ middleware.ts обновлен"

# Обновляем Nginx конфигурацию
puts "\n📝 Обновление Nginx конфигурации..."
send "sudo cp nginx/estenomada.production.conf /etc/nginx/sites-available/estenomada.production.conf\r"
expect {
    "password" {
        send "$password\r"
        exp_continue
    }
    "administrator@*" {
        puts "✅ Nginx конфигурация обновлена"
    }
}

# Тестируем Nginx конфигурацию
puts "\n🧪 Тестирование Nginx конфигурации..."
send "sudo nginx -t\r"
expect "administrator@*"

# Перезагружаем Nginx
puts "\n🔄 Перезагрузка Nginx..."
send "sudo systemctl reload nginx\r"
expect "administrator@*"
puts "✅ Nginx перезагружен"

# Переходим в backend
send "cd /var/www/estenomada/backend\r"
expect "administrator@*"

# Активируем виртуальное окружение
send "source venv/bin/activate\r"
expect "(venv)*"

# Собираем статические файлы Django
puts "\n📦 Сборка статических файлов Django..."
send "python3 manage.py collectstatic --noinput\r"
expect {
    "(venv)*" {
        puts "✅ Статические файлы собраны"
    }
    timeout {
        puts "⚠️  Timeout при сборке статических файлов"
    }
}

# Перезапускаем backend
puts "\n🔄 Перезапуск Django backend..."
send "sudo systemctl restart estenomada-backend\r"
expect "(venv)*"
puts "✅ Backend перезапущен"

# Выходим из виртуального окружения
send "deactivate\r"
expect "administrator@*"

# Переходим обратно в корень проекта
send "cd /var/www/estenomada\r"
expect "administrator@*"

# Пересобираем Next.js frontend
puts "\n🔨 Пересборка Next.js frontend..."
send "sudo chown -R administrator:administrator .next 2>/dev/null || true\r"
expect "administrator@*"
send "rm -rf .next\r"
expect "administrator@*"
send "npm run build\r"
expect {
    "administrator@*" {
        puts "✅ Next.js собран"
    }
    timeout {
        puts "⚠️  Timeout при сборке Next.js"
    }
}

# Меняем владельца .next на www-data
send "sudo chown -R www-data:www-data .next\r"
expect "administrator@*"

# Перезапускаем Next.js frontend
puts "\n🔄 Перезапуск Next.js frontend..."
send "sudo systemctl restart estenomada-frontend\r"
expect "administrator@*"
puts "✅ Frontend перезапущен"

# Проверяем статус сервисов
puts "\n📊 Проверка статуса сервисов..."
send "sudo systemctl status estenomada-frontend --no-pager -l | head -20\r"
expect "administrator@*"
send "sudo systemctl status estenomada-backend --no-pager -l | head -20\r"
expect "administrator@*"
send "sudo systemctl status nginx --no-pager -l | head -20\r"
expect "administrator@*"

puts "\n=========================================="
puts "✅ ГОТОВО!"
puts "=========================================="
puts "Django Admin доступна по адресу:"
puts "https://estenomada.es/admin/"
puts ""
puts "Логин: admin"
puts "Пароль: admin123"
puts "=========================================="

send "exit\r"
expect eof

