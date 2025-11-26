#!/bin/bash

# Скрипт для деплоя изменений настроек и логотипа

SERVER="administrator@85.190.102.101"
PASSWORD="Jovi4AndMay2020!"
REMOTE_PATH="/var/www/estenomada"

echo "Копирую миграцию..."
sshpass -p "$PASSWORD" scp backend/core/migrations/0012_add_logo_to_settings.py $SERVER:$REMOTE_PATH/backend/core/migrations/

echo "Копирую обновленные файлы..."
sshpass -p "$PASSWORD" scp backend/core/models.py $SERVER:$REMOTE_PATH/backend/core/
sshpass -p "$PASSWORD" scp backend/core/admin.py $SERVER:$REMOTE_PATH/backend/core/
sshpass -p "$PASSWORD" scp backend/core/signals.py $SERVER:$REMOTE_PATH/backend/core/
sshpass -p "$PASSWORD" scp backend/api/serializers.py $SERVER:$REMOTE_PATH/backend/api/
sshpass -p "$PASSWORD" scp backend/api/views.py $SERVER:$REMOTE_PATH/backend/api/
sshpass -p "$PASSWORD" scp backend/api/urls.py $SERVER:$REMOTE_PATH/backend/api/

echo "Копирую логотип..."
sshpass -p "$PASSWORD" scp public/logo_EN.png $SERVER:$REMOTE_PATH/backend/media/settings/logo_EN.png

echo "Применяю миграцию..."
sshpass -p "$PASSWORD" ssh $SERVER "cd $REMOTE_PATH/backend && source venv/bin/activate && python manage.py migrate core"

echo "Загружаю логотип в настройки через Django shell..."
sshpass -p "$PASSWORD" ssh $SERVER "cd $REMOTE_PATH/backend && source venv/bin/activate && python manage.py shell -c \"
from core.models import Settings
import os
from django.core.files import File

settings = Settings.get_settings()
logo_path = '/var/www/estenomada/backend/media/settings/logo_EN.png'
if os.path.exists(logo_path):
    with open(logo_path, 'rb') as f:
        settings.logo.save('logo_EN.png', File(f), save=True)
    print('Логотип успешно загружен')
else:
    print('Файл логотипа не найден:', logo_path)
\""

echo "Перезапускаю бэкенд..."
sshpass -p "$PASSWORD" ssh $SERVER "sudo systemctl restart estenomada-backend"

echo "Готово!"


