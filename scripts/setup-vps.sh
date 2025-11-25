#!/bin/bash

# Автоматическая установка на VPS
# Использование: ./setup-vps.sh

set -e

echo "🚀 Начинаем установку Este Nómada на VPS"

# Обновление системы
echo "📦 Обновляем систему..."
sudo apt update && sudo apt upgrade -y

# Установка Node.js
echo "📦 Устанавливаем Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Установка MySQL
echo "📦 Устанавливаем MySQL..."
sudo apt install -y mysql-server

# Установка Nginx
echo "📦 Устанавливаем Nginx..."
sudo apt install -y nginx

# Установка PM2 (опционально, для управления процессами)
echo "📦 Устанавливаем PM2..."
sudo npm install -g pm2

# Создание пользователя
echo "👤 Создаём пользователя estenomada..."
sudo adduser --disabled-password --gecos "" estenomada || true
sudo usermod -aG sudo estenomada

# Создание директории
echo "📁 Создаём директорию проекта..."
sudo mkdir -p /home/estenomada/este-nomada
sudo chown estenomada:estenomada /home/estenomada/este-nomada

echo "✅ Базовая установка завершена!"
echo ""
echo "Следующие шаги:"
echo "1. Загрузите файлы проекта в /home/estenomada/este-nomada"
echo "2. Настройте .env.production"
echo "3. Запустите: npm install && npm run build"
echo "4. Инициализируйте БД: npm run init-db"
echo "5. Создайте админа: npm run create-admin"
echo "6. Настройте systemd service (см. VPS_SETUP.md)"
echo "7. Настройте Nginx (см. VPS_SETUP.md)"



