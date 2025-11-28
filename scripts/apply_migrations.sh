#!/bin/bash
# Скрипт для применения миграций на сервере

set -e

DEPLOY_DIR="/var/www/estenomada"
BACKEND_DIR="$DEPLOY_DIR/backend"

echo "🚀 Применяю миграции на сервере..."

cd $BACKEND_DIR

# Проверяем Python
PYTHON_CMD=$(which python3.12 || which python3 || which python)
echo "Используем Python: $PYTHON_CMD"

# Активируем venv
if [ -f "venv/bin/python" ]; then
    PYTHON_CMD="venv/bin/python"
fi

# Применяем миграции
echo "📦 Применяю миграции..."
sudo -u www-data $PYTHON_CMD manage.py migrate --noinput

echo "✅ Миграции применены успешно!"

