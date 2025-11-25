#!/bin/bash

# Скрипт исправления проблем с Next.js в production
# Выполняет полную очистку и пересборку проекта

set -e

DEPLOY_DIR="/var/www/estenomada"
cd "$DEPLOY_DIR"

echo "🔧 Исправление проблем Next.js в production..."
echo "=============================================="

# Проверка прав
if [ "$EUID" -eq 0 ]; then
    echo "⚠️ Не запускайте скрипт от root!"
    echo "Используйте пользователя www-data или другого не-root пользователя"
    exit 1
fi

# 1. Остановка сервиса
echo ""
echo "1️⃣ Остановка сервиса..."
if systemctl is-active --quiet estenomada-frontend; then
    sudo systemctl stop estenomada-frontend
    echo "✅ Сервис остановлен"
else
    echo "ℹ️ Сервис уже остановлен"
fi

# 2. Очистка .next
echo ""
echo "2️⃣ Очистка директории .next..."
if [ -d ".next" ]; then
    rm -rf .next
    echo "✅ Директория .next удалена"
else
    echo "ℹ️ Директория .next не существует"
fi

# 3. Очистка кеша Next.js
echo ""
echo "3️⃣ Очистка кеша Next.js..."
rm -rf .next/cache 2>/dev/null || true
rm -rf node_modules/.cache 2>/dev/null || true
echo "✅ Кеш очищен"

# 4. Проверка переменных окружения
echo ""
echo "4️⃣ Проверка переменных окружения..."
if [ ! -f ".env.production" ]; then
    echo "❌ Файл .env.production не найден!"
    echo "Создайте его на основе env.production.example"
    exit 1
fi

# Убеждаемся, что NODE_ENV=production
if ! grep -q "^NODE_ENV=production" .env.production; then
    echo "⚠️ NODE_ENV не установлен в production, добавляю..."
    echo "NODE_ENV=production" >> .env.production
fi

# 5. Установка зависимостей (если нужно)
echo ""
echo "5️⃣ Проверка зависимостей..."
if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
    echo "📦 Установка зависимостей..."
    npm ci --production=false
    echo "✅ Зависимости установлены"
else
    echo "ℹ️ Зависимости уже установлены"
fi

# 6. Сборка проекта
echo ""
echo "6️⃣ Сборка Next.js проекта..."
echo "Это может занять несколько минут..."

# Устанавливаем переменные окружения для сборки
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1

# Загружаем переменные из .env.production
set -a
source .env.production
set +a

# Собираем проект
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Сборка завершена успешно"
else
    echo "❌ Ошибка при сборке проекта!"
    echo "Проверьте логи выше для деталей"
    exit 1
fi

# 7. Проверка результата сборки
echo ""
echo "7️⃣ Проверка результата сборки..."
if [ -d ".next" ]; then
    if [ -f ".next/BUILD_ID" ]; then
        BUILD_ID=$(cat .next/BUILD_ID)
        echo "✅ Сборка успешна, BUILD_ID: $BUILD_ID"
    else
        echo "⚠️ .next существует, но BUILD_ID не найден"
    fi
    
    # Проверка ключевых файлов
    if [ -f ".next/package.json" ] || [ -f ".next/server.js" ]; then
        echo "✅ Ключевые файлы сборки на месте"
    else
        echo "⚠️ Некоторые ключевые файлы отсутствуют"
    fi
    
    # Проверка и создание prerender-manifest.json
    echo ""
    echo "7️⃣.1 Проверка prerender-manifest.json..."
    if [ ! -f ".next/prerender-manifest.json" ]; then
        echo "⚠️ prerender-manifest.json отсутствует, создаю..."
        cat > .next/prerender-manifest.json << 'EOF'
{
  "version": 4,
  "routes": {},
  "dynamicRoutes": {},
  "notFoundRoutes": [],
  "preview": {
    "previewModeId": "",
    "previewModeSigningKey": "",
    "previewModeEncryptionKey": ""
  }
}
EOF
        echo "✅ prerender-manifest.json создан"
    else
        # Проверяем, что файл валиден
        if ! grep -q "previewModeId" .next/prerender-manifest.json 2>/dev/null; then
            echo "⚠️ prerender-manifest.json поврежден, пересоздаю..."
            cat > .next/prerender-manifest.json << 'EOF'
{
  "version": 4,
  "routes": {},
  "dynamicRoutes": {},
  "notFoundRoutes": [],
  "preview": {
    "previewModeId": "",
    "previewModeSigningKey": "",
    "previewModeEncryptionKey": ""
  }
}
EOF
            echo "✅ prerender-manifest.json пересоздан"
        else
            echo "✅ prerender-manifest.json существует и валиден"
        fi
    fi
else
    echo "❌ Директория .next не создана после сборки!"
    exit 1
fi

# 8. Проверка прав доступа
echo ""
echo "8️⃣ Проверка прав доступа..."
USER=$(whoami)
GROUP=$(id -gn)
echo "Текущий пользователь: $USER:$GROUP"

# Устанавливаем правильные права
chown -R $USER:$GROUP .next 2>/dev/null || true
chmod -R 755 .next 2>/dev/null || true
echo "✅ Права установлены"

# 9. Запуск сервиса
echo ""
echo "9️⃣ Запуск сервиса..."
sudo systemctl start estenomada-frontend

# Ждем немного для инициализации
sleep 3

# Проверка статуса
if systemctl is-active --quiet estenomada-frontend; then
    echo "✅ Сервис запущен успешно"
else
    echo "❌ Сервис не запустился!"
    echo "Проверьте логи: sudo journalctl -u estenomada-frontend -n 50"
    exit 1
fi

# 10. Проверка логов на ошибки
echo ""
echo "🔟 Проверка логов на ошибки..."
sleep 2
RECENT_ERRORS=$(journalctl -u estenomada-frontend -n 20 --no-pager | grep -i "error\|fatal\|cannot" || true)

if [ -z "$RECENT_ERRORS" ]; then
    echo "✅ Ошибок в логах не обнаружено"
else
    echo "⚠️ Обнаружены ошибки в логах:"
    echo "$RECENT_ERRORS"
fi

echo ""
echo "=============================================="
echo "✅ Процесс исправления завершен!"
echo ""
echo "Проверьте статус сервиса:"
echo "  sudo systemctl status estenomada-frontend"
echo ""
echo "Проверьте логи в реальном времени:"
echo "  sudo journalctl -u estenomada-frontend -f"
echo ""
echo "Проверьте доступность сайта:"
echo "  curl -I http://localhost:3000"
echo "=============================================="

