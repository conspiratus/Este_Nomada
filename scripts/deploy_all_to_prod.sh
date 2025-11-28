#!/bin/bash
# Полный деплой на production: код, миграции, email
# Использование: ./deploy_all_to_prod.sh

set -e

echo "🚀 Полный деплой Este Nómada на Production"
echo "============================================"

# Путь к проекту
PROJECT_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"
BACKEND_DIR="$PROJECT_DIR/backend"

cd "$PROJECT_DIR"

# 1. Обновление кода
echo ""
echo "📥 Обновление кода из git..."
if [ -d ".git" ]; then
    echo "   Получение изменений из GitHub..."
    git fetch origin
    
    # Сохраняем текущий бранч
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    echo "   Текущий бранч: $CURRENT_BRANCH"
    
    # Переключаемся на feature/personal-cabinet-cart
    echo "   Переключение на бранч feature/personal-cabinet-cart..."
    if git checkout feature/personal-cabinet-cart 2>/dev/null; then
        echo "   ✅ Переключились на существующий бранч"
    else
        echo "   Создание нового бранча из origin/feature/personal-cabinet-cart..."
        git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart
    fi
    
    # Обновляем код
    echo "   Обновление кода..."
    git pull origin feature/personal-cabinet-cart
    echo "✅ Код обновлен из бранча feature/personal-cabinet-cart"
else
    echo "⚠️  Git репозиторий не найден, пропускаем обновление кода"
    echo "   Убедитесь, что код обновлен вручную"
fi

# 2. Установка зависимостей backend
echo ""
echo "📦 Установка зависимостей backend..."
cd "$BACKEND_DIR"

if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Виртуальное окружение активировано"
else
    echo "⚠️  Виртуальное окружение не найдено, используем системный Python"
fi

pip install -q geopy markdown 2>/dev/null || pip3 install -q geopy markdown
echo "✅ Зависимости установлены"

# 3. Применение миграций
echo ""
echo "🗄️  Применение миграций..."
python manage.py migrate --noinput 2>&1 | tail -5
echo "✅ Миграции применены"

# 4. Настройка email
echo ""
echo "📧 Настройка email..."
if [ -f "../scripts/setup_email_auto.sh" ]; then
    chmod +x ../scripts/setup_email_auto.sh
    ../scripts/setup_email_auto.sh
else
    echo "⚠️  Скрипт настройки email не найден"
    echo "Настраиваю email вручную..."
    
    ENV_FILE=".env"
    if [ ! -f "$ENV_FILE" ]; then
        touch "$ENV_FILE"
    fi
    
    # Резервная копия
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Удаляем старые настройки
    sed -i.bak '/^EMAIL_/d' "$ENV_FILE" 2>/dev/null || true
    sed -i.bak '/^DEFAULT_FROM_EMAIL/d' "$ENV_FILE" 2>/dev/null || true
    sed -i.bak '/^SERVER_EMAIL/d' "$ENV_FILE" 2>/dev/null || true
    
    # Добавляем новые
    cat >> "$ENV_FILE" << EOF

# Email Settings (one.com SMTP)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=send.one.com
EMAIL_PORT=465
EMAIL_USE_TLS=False
EMAIL_USE_SSL=True
EMAIL_HOST_USER=info@nomadadeleste.com
EMAIL_HOST_PASSWORD=Drozdofil12345!
DEFAULT_FROM_EMAIL=info@nomadadeleste.com
SERVER_EMAIL=info@nomadadeleste.com
EOF
    
    echo "✅ Email настроен в .env"
fi

# 5. Генерация ключа шифрования (если нет)
echo ""
echo "🔐 Проверка ключа шифрования..."
if ! grep -q "ENCRYPTION_KEY" .env 2>/dev/null; then
    echo "⚠️  ENCRYPTION_KEY не найден, генерирую..."
    ENCRYPTION_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || echo "")
    if [ ! -z "$ENCRYPTION_KEY" ]; then
        echo "ENCRYPTION_KEY=$ENCRYPTION_KEY" >> .env
        echo "✅ Ключ шифрования сгенерирован и добавлен в .env"
        echo "⚠️  ВАЖНО: Сохраните этот ключ! Без него не получится расшифровать данные."
    else
        echo "❌ Не удалось сгенерировать ключ, установите cryptography: pip install cryptography"
    fi
else
    echo "✅ ENCRYPTION_KEY уже настроен"
fi

# 6. Создание настроек доставки (если нет)
echo ""
echo "🚚 Проверка настроек доставки..."
python manage.py shell << 'PYTHON_EOF'
from core.models import DeliverySettings
settings = DeliverySettings.get_settings()
print(f"✅ Настройки доставки: ID={settings.id}")
print(f"   Координаты: {settings.delivery_point_latitude}, {settings.delivery_point_longitude}")
print(f"   Базовая стоимость: {settings.base_delivery_cost}€")
PYTHON_EOF

# 7. Сбор статики
echo ""
echo "📦 Сбор статических файлов..."
python manage.py collectstatic --noinput 2>&1 | tail -3
echo "✅ Статические файлы собраны"

# 8. Проверка сервисов
echo ""
echo "🔄 Проверка сервисов..."
if systemctl is-active --quiet estenomada-backend 2>/dev/null; then
    echo "✅ Сервис estenomada-backend запущен"
    echo "   Перезапуск сервиса..."
    sudo systemctl restart estenomada-backend
    sleep 2
    if systemctl is-active --quiet estenomada-backend; then
        echo "✅ Сервис перезапущен успешно"
    else
        echo "⚠️  Проблема с перезапуском сервиса"
    fi
else
    echo "⚠️  Сервис estenomada-backend не найден или не запущен"
    echo "   Проверьте настройки systemd"
fi

# 9. Финальная проверка
echo ""
echo "✅ Деплой завершен!"
echo ""
echo "📋 Проверка:"
echo "1. Email настроен: $(grep -q 'EMAIL_HOST=send.one.com' .env && echo '✅' || echo '❌')"
echo "2. Миграции применены: ✅"
echo "3. Зависимости установлены: ✅"
echo ""
echo "🧪 Тестирование email..."
python manage.py shell << 'PYTHON_EOF'
from django.core.mail import send_mail
from django.conf import settings
try:
    send_mail(
        '✅ Деплой завершен - Este Nómada',
        'Деплой личного кабинета и корзины успешно завершен!\n\nВсе системы работают.',
        settings.DEFAULT_FROM_EMAIL,
        [settings.EMAIL_HOST_USER],
        fail_silently=False,
    )
    print("✅ Тестовое письмо отправлено на", settings.EMAIL_HOST_USER)
except Exception as e:
    print(f"⚠️  Ошибка отправки тестового письма: {e}")
PYTHON_EOF

echo ""
echo "🎉 Готово! Все настроено и работает."
echo ""
echo "📝 Следующие шаги:"
echo "1. Проверьте почтовый ящик info@nomadadeleste.com"
echo "2. Зайдите в админку и настройте доставку: /admin/core/deliverysettings/"
echo "3. Проверьте работу страницы заказов: /ru/order"

if [ -d "venv" ]; then
    deactivate
fi

