#!/bin/bash
# Скрипт для первоначальной настройки Django backend

set -e

echo "🔧 Настройка Django Backend для Este Nómada"

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKEND_DIR="backend"

if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Директория $BACKEND_DIR не найдена${NC}"
    exit 1
fi

cd "$BACKEND_DIR"

# Создание виртуального окружения
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}📦 Создание виртуального окружения...${NC}"
    python3 -m venv venv
fi

# Активация
source venv/bin/activate

# Установка зависимостей
echo -e "${YELLOW}📥 Установка зависимостей...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Проверка .env файла
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📝 Создание .env файла...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Не забудь заполнить .env файл!${NC}"
    else
        echo -e "${RED}❌ .env.example не найден${NC}"
    fi
fi

# Инициализация БД
echo -e "${YELLOW}🗄️  Инициализация базы данных...${NC}"
python scripts/init_db.py

# Создание администратора
echo -e "${YELLOW}👤 Создание администратора...${NC}"
read -p "Имя пользователя (по умолчанию: admin): " username
username=${username:-admin}
read -sp "Пароль (по умолчанию: admin123): " password
password=${password:-admin123}
echo ""

python scripts/create_admin.py --username "$username" --password "$password"

echo -e "${GREEN}✅ Настройка завершена!${NC}"
echo -e "${YELLOW}💡 Для запуска:${NC}"
echo "   source venv/bin/activate"
echo "   python manage.py runserver"



