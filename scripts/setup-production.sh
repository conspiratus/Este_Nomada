#!/bin/bash

# Скрипт настройки production окружения на сервере
# Выполняется на сервере после распаковки архива

set -e

DEPLOY_DIR="/var/www/estenomada"
BACKEND_DIR="$DEPLOY_DIR/backend"
FRONTEND_DIR="$DEPLOY_DIR"

echo "🔧 Настраиваем production окружение..."

# 1. Установка зависимостей фронтенда
echo "📦 Устанавливаем зависимости фронтенда..."
cd $FRONTEND_DIR
npm ci --only=production

# 2. Настройка бэкенда
echo "🐍 Настраиваем Django backend..."
cd $BACKEND_DIR

# Создание виртуального окружения, если его нет
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Активация и установка зависимостей
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Создание директорий
mkdir -p staticfiles media logs

# Применение миграций
python manage.py migrate --noinput

# Сборка статических файлов
python manage.py collectstatic --noinput

# 3. Настройка systemd сервисов
echo "⚙️ Настраиваем systemd сервисы..."
sudo cp $DEPLOY_DIR/systemd/estenomada-backend.service /etc/systemd/system/
sudo cp $DEPLOY_DIR/systemd/estenomada-celery.service /etc/systemd/system/
sudo cp $DEPLOY_DIR/systemd/estenomada-celery-beat.service /etc/systemd/system/
sudo cp $DEPLOY_DIR/systemd/estenomada-frontend.service /etc/systemd/system/

sudo systemctl daemon-reload

# 4. Настройка Nginx
echo "🌐 Настраиваем Nginx..."
if [ -f "$DEPLOY_DIR/nginx/estenomada.production.conf" ]; then
    sudo cp $DEPLOY_DIR/nginx/estenomada.production.conf /etc/nginx/sites-available/estenomada
    if [ ! -f "/etc/nginx/sites-enabled/estenomada" ]; then
        sudo ln -s /etc/nginx/sites-available/estenomada /etc/nginx/sites-enabled/
    fi
    sudo nginx -t
fi

# 5. Запуск сервисов
echo "🚀 Запускаем сервисы..."
sudo systemctl enable estenomada-backend
sudo systemctl enable estenomada-celery
sudo systemctl enable estenomada-celery-beat
sudo systemctl enable estenomada-frontend

sudo systemctl restart estenomada-backend
sudo systemctl restart estenomada-celery
sudo systemctl restart estenomada-celery-beat
sudo systemctl restart estenomada-frontend

# 6. Перезагрузка Nginx
if [ -f "/etc/nginx/sites-enabled/estenomada" ]; then
    sudo systemctl reload nginx
fi

echo "✅ Production окружение настроено!"
echo ""
echo "📋 Проверка статуса сервисов:"
echo "  sudo systemctl status estenomada-backend"
echo "  sudo systemctl status estenomada-frontend"
echo "  sudo systemctl status estenomada-celery"
echo ""
echo "📋 Логи:"
echo "  sudo journalctl -u estenomada-backend -f"
echo "  sudo journalctl -u estenomada-frontend -f"




