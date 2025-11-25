#!/bin/bash

# Скрипт для деплоя в production
# Использование: ./scripts/deploy-production.sh [server_user@server_ip]

set -e

SERVER=${1:-"user@server"}
DEPLOY_DIR="/var/www/estenomada"
BACKEND_DIR="$DEPLOY_DIR/backend"
FRONTEND_DIR="$DEPLOY_DIR"

echo "🚀 Начинаем деплой в production на $SERVER"

# 1. Сборка фронтенда
echo "📦 Собираем фронтенд..."
npm run build

# 2. Создание архива
echo "📦 Создаём архив для деплоя..."
tar -czf deploy-production.tar.gz \
    .next \
    public \
    package.json \
    package-lock.json \
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

# 3. Загрузка на сервер
echo "📤 Загружаем на сервер..."
scp deploy-production.tar.gz $SERVER:/tmp/

# 4. Выполнение на сервере
echo "📥 Распаковываем и настраиваем на сервере..."
ssh $SERVER << ENDSSH
set -e

# Создание директорий
sudo mkdir -p $DEPLOY_DIR
sudo mkdir -p $BACKEND_DIR
sudo mkdir -p $FRONTEND_DIR

# Распаковка
cd /tmp
sudo tar -xzf deploy-production.tar.gz -C $DEPLOY_DIR --strip-components=0
sudo rm deploy-production.tar.gz

# Установка прав
sudo chown -R www-data:www-data $DEPLOY_DIR

# Запуск скрипта настройки
sudo bash $DEPLOY_DIR/scripts/setup-production.sh

echo "✅ Деплой завершён!"
ENDSSH

# Очистка
rm deploy-production.tar.gz

echo "✅ Готово! Проект задеплоен в production."




