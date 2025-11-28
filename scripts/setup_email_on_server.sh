#!/bin/bash
# Скрипт для настройки email на сервере one.com

set -e

echo "📧 Настройка email для Este Nómada"
echo "===================================="

# Определяем путь к проекту
PROJECT_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"
BACKEND_DIR="$PROJECT_DIR/backend"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Директория backend не найдена: $BACKEND_DIR"
    echo "Проверьте путь к проекту"
    exit 1
fi

echo "✅ Найдена директория проекта: $BACKEND_DIR"

# Переходим в директорию backend
cd "$BACKEND_DIR"

# Проверяем наличие .env файла
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Создаю файл .env..."
    touch "$ENV_FILE"
fi

# Создаем резервную копию
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Создана резервная копия .env"
fi

# Настройки SMTP one.com
echo ""
echo "📧 Настройка SMTP one.com..."
echo "SMTP server: send.one.com"
echo "SMTP port: 465 (SSL)"

# Читаем существующие настройки или запрашиваем у пользователя
if grep -q "EMAIL_HOST_USER" "$ENV_FILE"; then
    CURRENT_EMAIL=$(grep "EMAIL_HOST_USER" "$ENV_FILE" | cut -d'=' -f2)
    echo "Текущий email: $CURRENT_EMAIL"
    read -p "Использовать этот email? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "Введите email для отправки писем: " EMAIL_USER
    else
        EMAIL_USER="$CURRENT_EMAIL"
    fi
else
    read -p "Введите email для отправки писем (например, info@estenomada.es): " EMAIL_USER
fi

if [ -z "$EMAIL_USER" ]; then
    echo "❌ Email не указан"
    exit 1
fi

read -sp "Введите пароль от email: " EMAIL_PASSWORD
echo ""

if [ -z "$EMAIL_PASSWORD" ]; then
    echo "❌ Пароль не указан"
    exit 1
fi

# Обновляем или добавляем настройки email
echo ""
echo "⚙️  Обновление настроек email в .env..."

# Удаляем старые настройки email, если есть
sed -i.bak '/^EMAIL_/d' "$ENV_FILE"
sed -i.bak '/^DEFAULT_FROM_EMAIL/d' "$ENV_FILE"
sed -i.bak '/^SERVER_EMAIL/d' "$ENV_FILE"

# Добавляем новые настройки
cat >> "$ENV_FILE" << EOF

# Email Settings (one.com SMTP)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=send.one.com
EMAIL_PORT=465
EMAIL_USE_TLS=False
EMAIL_USE_SSL=True
EMAIL_HOST_USER=$EMAIL_USER
EMAIL_HOST_PASSWORD=$EMAIL_PASSWORD
DEFAULT_FROM_EMAIL=$EMAIL_USER
SERVER_EMAIL=$EMAIL_USER
EOF

echo "✅ Настройки email добавлены в .env"

# Проверяем, что Django может использовать эти настройки
echo ""
echo "🧪 Тестирование настроек..."

# Создаем тестовый скрипт
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" << 'PYTHON_EOF'
import os
import sys
import django

# Настройка Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from django.conf import settings
from django.core.mail import send_mail

print("📧 Настройки email:")
print(f"  EMAIL_HOST: {settings.EMAIL_HOST}")
print(f"  EMAIL_PORT: {settings.EMAIL_PORT}")
print(f"  EMAIL_USE_SSL: {settings.EMAIL_USE_SSL}")
print(f"  EMAIL_HOST_USER: {settings.EMAIL_HOST_USER}")
print(f"  DEFAULT_FROM_EMAIL: {settings.DEFAULT_FROM_EMAIL}")
print("")

# Запрашиваем email для теста
test_email = input("Введите email для тестового письма (или Enter для пропуска): ").strip()

if test_email:
    try:
        print("📤 Отправка тестового письма...")
        send_mail(
            subject='Test Email from Este Nómada',
            message='Это тестовое письмо от Este Nómada. Если вы получили это письмо, настройка email работает корректно!',
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[test_email],
            fail_silently=False,
        )
        print("✅ Тестовое письмо отправлено успешно!")
        print("   Проверьте папку 'Входящие' и 'Спам'")
    except Exception as e:
        print(f"❌ Ошибка при отправке: {e}")
        print("   Проверьте логи: tail -f logs/django.log")
else:
    print("⏭️  Тест отправки пропущен")
PYTHON_EOF

# Активируем venv если есть
if [ -d "venv" ]; then
    source venv/bin/activate
    python "$TEST_SCRIPT"
    deactivate
else
    python3 "$TEST_SCRIPT"
fi

rm "$TEST_SCRIPT"

echo ""
echo "✅ Настройка завершена!"
echo ""
echo "📝 Следующие шаги:"
echo "1. Проверьте, что тестовое письмо пришло"
echo "2. Если письмо не пришло, проверьте логи: tail -f $BACKEND_DIR/logs/django.log"
echo "3. Убедитесь, что пароль от email правильный"
echo "4. Проверьте настройки в .env: cat $BACKEND_DIR/.env | grep EMAIL"
echo ""
echo "🔒 Безопасность:"
echo "- Файл .env содержит пароли, не коммитьте его в git!"
echo "- Резервная копия сохранена: ${ENV_FILE}.backup.*"

