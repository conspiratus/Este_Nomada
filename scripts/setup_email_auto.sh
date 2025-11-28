#!/bin/bash
# Автоматическая настройка email на сервере one.com
# Использование: ./setup_email_auto.sh

set -e

echo "📧 Автоматическая настройка email для Este Nómada"
echo "=================================================="

# Данные email
EMAIL_USER="info@nomadadeleste.com"
EMAIL_PASSWORD="Drozdofil12345!"

# Определяем путь к проекту
PROJECT_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"
BACKEND_DIR="$PROJECT_DIR/backend"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Директория backend не найдена: $BACKEND_DIR"
    echo "Текущая директория: $(pwd)"
    echo "Проверьте путь к проекту"
    exit 1
fi

echo "✅ Найдена директория проекта: $BACKEND_DIR"
cd "$BACKEND_DIR"

# Проверяем наличие .env файла
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Создаю файл .env..."
    touch "$ENV_FILE"
fi

# Создаем резервную копию
if [ -f "$ENV_FILE" ]; then
    BACKUP_FILE="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ENV_FILE" "$BACKUP_FILE"
    echo "✅ Создана резервная копия: $BACKUP_FILE"
fi

# Обновляем настройки email
echo ""
echo "⚙️  Настройка SMTP one.com..."

# Удаляем старые настройки email, если есть
sed -i.bak '/^EMAIL_/d' "$ENV_FILE" 2>/dev/null || true
sed -i.bak '/^DEFAULT_FROM_EMAIL/d' "$ENV_FILE" 2>/dev/null || true
sed -i.bak '/^SERVER_EMAIL/d' "$ENV_FILE" 2>/dev/null || true

# Добавляем новые настройки
cat >> "$ENV_FILE" << EOF

# Email Settings (one.com SMTP) - настроено автоматически
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
echo "   EMAIL_HOST: send.one.com"
echo "   EMAIL_PORT: 465 (SSL)"
echo "   EMAIL_HOST_USER: $EMAIL_USER"

# Проверяем настройки
echo ""
echo "📋 Проверка настроек в .env:"
grep "^EMAIL_" "$ENV_FILE" | sed 's/PASSWORD=.*/PASSWORD=***/' || echo "Настройки не найдены"

# Тестируем отправку письма
echo ""
echo "🧪 Тестирование отправки email..."

# Создаем тестовый скрипт
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" << 'PYTHON_EOF'
import os
import sys
import django

# Настройка Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')

try:
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
    
    # Отправляем тестовое письмо на тот же email
    test_email = settings.EMAIL_HOST_USER
    print(f"📤 Отправка тестового письма на {test_email}...")
    
    try:
        send_mail(
            subject='✅ Email настроен успешно - Este Nómada',
            message='Это тестовое письмо подтверждает, что настройка email работает корректно!\n\nЕсли вы получили это письмо, значит все настроено правильно.',
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[test_email],
            fail_silently=False,
        )
        print("✅ Тестовое письмо отправлено успешно!")
        print(f"   Проверьте почтовый ящик {test_email}")
        print("   Проверьте папку 'Входящие' и 'Спам'")
    except Exception as e:
        print(f"❌ Ошибка при отправке: {e}")
        print("   Проверьте:")
        print("   1. Правильность пароля в .env")
        print("   2. Логи: tail -f logs/django.log")
        print("   3. Подключение к SMTP: telnet send.one.com 465")
        sys.exit(1)
        
except Exception as e:
    print(f"❌ Ошибка при настройке Django: {e}")
    sys.exit(1)
PYTHON_EOF

# Активируем venv если есть и запускаем тест
if [ -d "venv" ]; then
    source venv/bin/activate
    python "$TEST_SCRIPT"
    deactivate
else
    python3 "$TEST_SCRIPT"
fi

rm "$TEST_SCRIPT"

echo ""
echo "✅ Настройка email завершена!"
echo ""
echo "📝 Следующие шаги:"
echo "1. Проверьте почтовый ящик $EMAIL_USER - должно прийти тестовое письмо"
echo "2. Если письмо не пришло, проверьте логи: tail -f $BACKEND_DIR/logs/django.log"
echo "3. Убедитесь, что пароль правильный в .env"
echo ""
echo "🔒 Безопасность:"
echo "- Файл .env содержит пароли, не коммитьте его в git!"
echo "- Резервная копия сохранена: $BACKUP_FILE"
echo ""
echo "📧 Email готов к использованию для:"
echo "   - Подтверждения регистрации"
echo "   - Уведомлений о заказах"
echo "   - Восстановления паролей"

