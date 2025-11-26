#!/bin/bash
# Скрипт для исправления конфликта миграций на сервере
# Удаляет старую миграцию 0018_remove_ttk_comments, которая была переименована в 0019

set -e

MIGRATIONS_DIR="/var/www/estenomada/backend/core/migrations"
OLD_MIGRATION="0018_remove_ttk_comments.py"

echo "🔧 Исправляю конфликт миграций на сервере..."

# Удаляем старую миграцию 0018_remove_ttk_comments (она переименована в 0019)
if [ -f "$MIGRATIONS_DIR/$OLD_MIGRATION" ]; then
    echo "📝 Удаляю старую миграцию $OLD_MIGRATION..."
    sudo rm "$MIGRATIONS_DIR/$OLD_MIGRATION"
    echo "✅ Старая миграция удалена"
else
    echo "ℹ️  Старая миграция уже удалена"
fi

# Проверяем статус миграций
echo ""
echo "📋 Проверяю статус миграций..."
cd /var/www/estenomada/backend
sudo -u www-data venv/bin/python manage.py showmigrations core | tail -10

echo ""
echo "✅ Конфликт миграций исправлен!"

