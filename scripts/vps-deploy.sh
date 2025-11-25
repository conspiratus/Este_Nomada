#!/bin/bash

# Скрипт для деплоя на VPS
# Использование: ./vps-deploy.sh user@vps-ip

set -e

VPS_HOST=$1
VPS_USER=${VPS_HOST%%@*}
VPS_IP=${VPS_HOST##*@}

if [ -z "$VPS_HOST" ]; then
    echo "Использование: ./vps-deploy.sh user@vps-ip"
    exit 1
fi

echo "🚀 Начинаем деплой на $VPS_HOST"

# Сборка проекта
echo "📦 Собираем проект..."
npm run build

# Создание архива
echo "📦 Создаём архив..."
tar -czf deploy.tar.gz \
    .next \
    public \
    package.json \
    package-lock.json \
    next.config.mjs \
    server.js \
    tsconfig.json \
    lib \
    app \
    components \
    types \
    middleware.ts \
    i18n.ts \
    messages \
    scripts

# Загрузка на сервер
echo "📤 Загружаем на сервер..."
scp deploy.tar.gz $VPS_HOST:/tmp/

# Распаковка и установка на сервере
echo "📥 Распаковываем на сервере..."
ssh $VPS_HOST << 'ENDSSH'
cd /home/estenomada/este-nomada || exit 1
tar -xzf /tmp/deploy.tar.gz
rm /tmp/deploy.tar.gz
npm install --production
sudo systemctl restart estenomada
echo "✅ Деплой завершён!"
ENDSSH

# Очистка
rm deploy.tar.gz

echo "✅ Готово!"




