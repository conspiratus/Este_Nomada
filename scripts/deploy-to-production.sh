#!/bin/bash

# Полный скрипт деплоя в production
# Использование: ./scripts/deploy-to-production.sh

set -e

SERVER="czjey8yl0_ssh@ssh.czjey8yl0.service.one"
REMOTE_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"
PASSWORD="Drozdofil12345!"

echo "🚀 Начинаем деплой в production..."

# 1. Сборка фронтенда
echo "📦 Собираем фронтенд..."
npm run build

# 2. Создание архива
echo "📦 Создаём архив..."
tar -czf deploy-full.tar.gz \
    .next \
    public \
    package*.json \
    next.config.mjs \
    server.js \
    tsconfig.json \
    middleware.ts \
    i18n.ts \
    lib \
    app \
    components \
    types \
    messages \
    backend \
    nginx \
    systemd \
    scripts/deploy-production.sh \
    scripts/setup-production.sh

echo "📤 Загружаем на сервер..."
expect << EXPECT_SCRIPT
set timeout 300
spawn scp -P 22 -o StrictHostKeyChecking=no deploy-full.tar.gz ${SERVER}:${REMOTE_DIR}/
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo "📥 Распаковываем на сервере..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && tar -xzf deploy-full.tar.gz && rm deploy-full.tar.gz"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo "📥 Устанавливаем зависимости фронтенда..."
expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && npm install --production"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo "🐍 Настраиваем Django backend..."
expect << EXPECT_SCRIPT
set timeout 600
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo "📝 Создаём .env файлы..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && cat > .env.production << 'ENVEOF'
SECRET_KEY=django-insecure-production-key-change-this
DEBUG=False
ALLOWED_HOSTS=estenomada.es,www.estenomada.es,api.estenomada.es
USE_SQLITE=False
DB_NAME=czjey8yl0_estenomada
DB_USER=czjey8yl0_estenomada
DB_PASSWORD=Jovi4AndMay2020!
DB_HOST=localhost
DB_PORT=3306
CORS_ALLOWED_ORIGINS=https://estenomada.es,https://www.estenomada.es
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
ENVEOF
"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && cat > .env.production << 'ENVEOF'
NODE_ENV=production
PORT=3000
HOSTNAME=0.0.0.0
NEXT_PUBLIC_API_URL=https://api.estenomada.es/api
NEXT_PUBLIC_BASE_URL=https://estenomada.es
ENVEOF
"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo "🗄️ Применяем миграции..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py migrate --noinput && python manage.py collectstatic --noinput"
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

echo "👤 Создаём суперпользователя..."
expect << EXPECT_SCRIPT
set timeout 300
spawn ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py shell -c \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@estenomada.es', 'admin123')\""
expect {
    "password:" {
        send "${PASSWORD}\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    eof {
        exit
    }
}
EXPECT_SCRIPT

# Очистка
rm -f deploy-full.tar.gz

echo ""
echo "✅ Деплой завершён!"
echo ""
echo "📋 Что сделано:"
echo "   1. ✅ Собран фронтенд"
echo "   2. ✅ Загружен на сервер"
echo "   3. ✅ Установлены зависимости"
echo "   4. ✅ Настроены .env файлы"
echo "   5. ✅ Применены миграции"
echo "   6. ✅ Создан суперпользователь (admin/admin123)"
echo ""
echo "🌐 Доступ:"
echo "   - Frontend: https://estenomada.es"
echo "   - Backend API: https://api.estenomada.es/api"
echo "   - Admin: https://api.estenomada.es/admin"
echo ""
echo "⚠️ Важно:"
echo "   - Настрой Node.js приложение в панели one.com"
echo "   - Entry point: server.js"
echo "   - Working directory: ${REMOTE_DIR}"



