#!/bin/bash

# Скрипт диагностики и исправления проблем с Next.js в production
# Запускать на сервере в директории /var/www/estenomada

set -e

DEPLOY_DIR="/var/www/estenomada"
cd "$DEPLOY_DIR"

echo "🔍 Диагностика проблем Next.js..."
echo "=================================="

# 1. Проверка переменных окружения
echo ""
echo "1️⃣ Проверка переменных окружения..."
if [ -f ".env.production" ]; then
    echo "✅ Файл .env.production найден"
    echo "Содержимое (без секретов):"
    grep -E "^(NODE_ENV|PORT|HOSTNAME|NEXT_PUBLIC)" .env.production || echo "⚠️ Переменные Next.js не найдены"
else
    echo "❌ Файл .env.production не найден!"
    exit 1
fi

# 2. Проверка структуры .next
echo ""
echo "2️⃣ Проверка структуры .next..."
if [ -d ".next" ]; then
    echo "✅ Директория .next существует"
    
    # Проверка ключевых файлов
    REQUIRED_FILES=(
        ".next/BUILD_ID"
        ".next/package.json"
        ".next/standalone/package.json"
        ".next/server.js"
    )
    
    MISSING_FILES=()
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        echo "✅ Все ключевые файлы на месте"
    else
        echo "⚠️ Отсутствуют файлы:"
        for file in "${MISSING_FILES[@]}"; do
            echo "   - $file"
        done
        echo "💡 Требуется пересборка проекта"
    fi
    
    # Проверка размера .next
    NEXT_SIZE=$(du -sh .next 2>/dev/null | cut -f1)
    echo "📦 Размер .next: $NEXT_SIZE"
    
    if [ "$NEXT_SIZE" = "0" ] || [ -z "$NEXT_SIZE" ]; then
        echo "❌ Директория .next пуста или повреждена!"
    fi
else
    echo "❌ Директория .next не существует!"
    echo "💡 Требуется сборка проекта"
fi

# 3. Проверка логов systemd
echo ""
echo "3️⃣ Проверка логов systemd..."
if systemctl is-active --quiet estenomada-frontend; then
    echo "✅ Сервис estenomada-frontend активен"
    echo ""
    echo "Последние 50 строк логов:"
    journalctl -u estenomada-frontend -n 50 --no-pager || echo "⚠️ Не удалось получить логи"
else
    echo "❌ Сервис estenomada-frontend не активен"
    echo "Статус:"
    systemctl status estenomada-frontend --no-pager -l || true
fi

# 4. Проверка Node.js и npm
echo ""
echo "4️⃣ Проверка окружения..."
NODE_VERSION=$(node --version 2>/dev/null || echo "не установлен")
NPM_VERSION=$(npm --version 2>/dev/null || echo "не установлен")
echo "Node.js: $NODE_VERSION"
echo "npm: $NPM_VERSION"

# 5. Проверка зависимостей
echo ""
echo "5️⃣ Проверка зависимостей..."
if [ -d "node_modules" ]; then
    echo "✅ node_modules существует"
    MODULES_SIZE=$(du -sh node_modules 2>/dev/null | cut -f1)
    echo "📦 Размер node_modules: $MODULES_SIZE"
else
    echo "❌ node_modules не существует!"
    echo "💡 Требуется установка зависимостей"
fi

# 6. Проверка package.json
echo ""
echo "6️⃣ Проверка package.json..."
if [ -f "package.json" ]; then
    echo "✅ package.json найден"
    if grep -q '"start"' package.json; then
        START_CMD=$(grep -A 1 '"start"' package.json | grep -o '".*"' | head -1)
        echo "   Команда start: $START_CMD"
    else
        echo "⚠️ Скрипт 'start' не найден в package.json"
    fi
else
    echo "❌ package.json не найден!"
    exit 1
fi

echo ""
echo "=================================="
echo "🔧 Предлагаемые действия:"
echo ""
echo "1. Очистить .next и пересобрать:"
echo "   rm -rf .next"
echo "   npm run build"
echo ""
echo "2. Переустановить зависимости:"
echo "   rm -rf node_modules package-lock.json"
echo "   npm install"
echo "   npm run build"
echo ""
echo "3. Перезапустить сервис:"
echo "   sudo systemctl restart estenomada-frontend"
echo ""
echo "4. Проверить логи в реальном времени:"
echo "   sudo journalctl -u estenomada-frontend -f"
echo ""
echo "=================================="

