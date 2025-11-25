#!/bin/bash

# Деплой исправлений для гидратации React (bash версия)

set -e

SERVER="administrator@85.190.102.101"
PASSWORD="Jovi4AndMay2020!"
REMOTE_DIR="/var/www/estenomada"

echo "=========================================="
echo "Деплой исправлений гидратации React"
echo "=========================================="

# Загружаем файлы
echo ""
echo "📤 Загрузка файлов..."
sshpass -p "$PASSWORD" scp /Users/conspiratus/Projects/Este_Nomada/app/layout.tsx $SERVER:/tmp/layout.tsx
sshpass -p "$PASSWORD" scp "/Users/conspiratus/Projects/Este_Nomada/app/[locale]/layout.tsx" $SERVER:/tmp/locale_layout.tsx

# Подключаемся и применяем изменения
echo ""
echo "📥 Применение изменений..."
sshpass -p "$PASSWORD" ssh $SERVER << 'ENDSSH'
cd /var/www/estenomada

# Останавливаем фронтенд
echo "🛑 Остановка фронтенда..."
sudo systemctl stop estenomada-frontend

# Копируем файлы
echo "📥 Копирование файлов..."
sudo cp /tmp/layout.tsx app/layout.tsx
sudo cp /tmp/locale_layout.tsx 'app/[locale]/layout.tsx'
sudo chown -R www-data:www-data app/

# Пересобираем фронтенд
echo "🔨 Пересборка фронтенда..."
sudo chown -R administrator:administrator .
rm -rf .next
npm run build

# Устанавливаем права
sudo chown -R www-data:www-data .next

# Создаём prerender-manifest.json если нужно
if [ ! -f .next/prerender-manifest.json ]; then
    python3 -c "import json; json.dump({'version': 4, 'routes': {}, 'dynamicRoutes': {}, 'notFoundRoutes': [], 'preview': {'previewModeId': '', 'previewModeSigningKey': '', 'previewModeEncryptionKey': ''}}, open('.next/prerender-manifest.json', 'w'), indent=2)"
    sudo chown www-data:www-data .next/prerender-manifest.json
fi

# Запускаем фронтенд
echo "🚀 Запуск фронтенда..."
sudo systemctl start estenomada-frontend

# Проверяем статус
echo "🔍 Проверка статуса..."
sleep 8
sudo systemctl status estenomada-frontend --no-pager | head -20
ENDSSH

echo ""
echo "=========================================="
echo "✅ Деплой завершён!"
echo "Проверь сайт: https://estenomada.es"
echo "Ошибки гидратации должны быть исправлены."
echo "=========================================="

