#!/bin/bash
# Скрипт для деплоя Django backend

set -e

echo "🚀 Деплой Django Backend для Este Nómada"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка переменных окружения
if [ -z "$BACKEND_DIR" ]; then
    BACKEND_DIR="backend"
fi

if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Директория $BACKEND_DIR не найдена${NC}"
    exit 1
fi

cd "$BACKEND_DIR"

# Активация виртуального окружения
if [ -d "venv" ]; then
    echo -e "${YELLOW}📦 Активация виртуального окружения...${NC}"
    source venv/bin/activate
else
    echo -e "${YELLOW}📦 Создание виртуального окружения...${NC}"
    python3 -m venv venv
    source venv/bin/activate
fi

# Установка зависимостей
echo -e "${YELLOW}📥 Установка зависимостей...${NC}"
pip install -r requirements.txt

# Применение миграций
echo -e "${YELLOW}🔄 Применение миграций...${NC}"
python manage.py makemigrations
python manage.py migrate

# Сбор статических файлов
echo -e "${YELLOW}📦 Сбор статических файлов...${NC}"
python manage.py collectstatic --noinput

# Создание директории для логов
mkdir -p logs

echo -e "${GREEN}✅ Деплой завершен!${NC}"
echo -e "${YELLOW}💡 Для запуска используй:${NC}"
echo "   python manage.py runserver  # Development"
echo "   gunicorn este_nomada.wsgi:application  # Production"



