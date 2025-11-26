#!/bin/bash

# Быстрое исправление prerender-manifest.json
# Используется когда проблема только в этом файле

set -e

DEPLOY_DIR="/var/www/estenomada"
cd "$DEPLOY_DIR"

echo "🔧 Быстрое исправление prerender-manifest.json..."
echo "================================================"

# Проверка, что мы в правильной директории
if [ ! -f "package.json" ]; then
    echo "❌ Файл package.json не найден!"
    echo "Убедитесь, что вы находитесь в директории проекта"
    exit 1
fi

# Остановка сервиса
echo ""
echo "1️⃣ Остановка сервиса..."
if systemctl is-active --quiet estenomada-frontend; then
    sudo systemctl stop estenomada-frontend
    echo "✅ Сервис остановлен"
else
    echo "ℹ️ Сервис уже остановлен"
fi

# Проверка существования .next
if [ ! -d ".next" ]; then
    echo "❌ Директория .next не существует!"
    echo "Требуется полная сборка проекта: npm run build"
    exit 1
fi

# Создание/исправление prerender-manifest.json
echo ""
echo "2️⃣ Создание prerender-manifest.json..."
# Используем sudo для создания файла, если нет прав
if [ -w ".next" ]; then
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
else
    sudo tee .next/prerender-manifest.json > /dev/null << 'EOF'
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
fi

# Установка прав
SERVICE_USER=$(grep "^User=" /etc/systemd/system/estenomada-frontend.service 2>/dev/null | cut -d= -f2 || echo "www-data")
sudo chown $SERVICE_USER:$SERVICE_USER .next/prerender-manifest.json 2>/dev/null || true
sudo chmod 644 .next/prerender-manifest.json 2>/dev/null || true

echo "✅ prerender-manifest.json создан/обновлен"

# Проверка файла
if [ -f ".next/prerender-manifest.json" ] && grep -q "previewModeId" .next/prerender-manifest.json; then
    echo "✅ Файл валиден"
else
    echo "❌ Ошибка при создании файла!"
    exit 1
fi

# Запуск сервиса
echo ""
echo "3️⃣ Запуск сервиса..."
sudo systemctl start estenomada-frontend

# Ждем инициализации
sleep 3

# Проверка статуса
if systemctl is-active --quiet estenomada-frontend; then
    echo "✅ Сервис запущен успешно"
else
    echo "❌ Сервис не запустился!"
    echo "Проверьте логи: sudo journalctl -u estenomada-frontend -n 50"
    exit 1
fi

echo ""
echo "================================================"
echo "✅ Исправление завершено!"
echo ""
echo "Проверьте логи:"
echo "  sudo journalctl -u estenomada-frontend -f"
echo "================================================"

