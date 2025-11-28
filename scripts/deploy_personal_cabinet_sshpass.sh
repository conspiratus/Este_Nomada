#!/bin/bash
# Деплой личного кабинета с использованием sshpass
# Использование: ./scripts/deploy_personal_cabinet_sshpass.sh

set -e

SERVER="czjey8yl0_ssh@ssh.czjey8yl0.service.one"
REMOTE_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"
PASSWORD="Drozdofil12345!"

echo "🚀 Деплой личного кабинета и корзины на production"
echo "=================================================="

# Проверяем sshpass
if ! command -v sshpass &> /dev/null; then
    echo "❌ sshpass не установлен. Устанавливаю..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y sshpass || sudo yum install -y sshpass
    fi
fi

# 1. Обновление кода
echo ""
echo "📥 Обновление кода из бранча feature/personal-cabinet-cart..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart"

# 2. Установка зависимостей
echo ""
echo "📦 Установка зависимостей backend..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && pip install -q geopy markdown"

# 3. Применение миграций
echo ""
echo "🗄️  Применение миграций..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py migrate --noinput"

# 4. Настройка email
echo ""
echo "📧 Настройка email..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && if [ -f .env ]; then cp .env .env.backup.\$(date +%Y%m%d_%H%M%S); fi && sed -i.bak '/^EMAIL_/d' .env 2>/dev/null || true && sed -i.bak '/^DEFAULT_FROM_EMAIL/d' .env 2>/dev/null || true && sed -i.bak '/^SERVER_EMAIL/d' .env 2>/dev/null || true && cat >> .env << 'ENVEOF'

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
ENVEOF
"

# 5. ENCRYPTION_KEY
echo ""
echo "🔐 Проверка ENCRYPTION_KEY..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && if ! grep -q '^ENCRYPTION_KEY=' .env 2>/dev/null; then ENC_KEY=\$(python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'); echo \"ENCRYPTION_KEY=\$ENC_KEY\" >> .env && echo 'Ключ сгенерирован'; else echo 'Ключ уже есть'; fi"

# 6. Настройки доставки
echo ""
echo "🚚 Проверка настроек доставки..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py shell -c \"from core.models import DeliverySettings; s = DeliverySettings.get_settings(); print(f'Настройки доставки: ID={s.id}')\""

# 7. Сбор статики
echo ""
echo "📦 Сбор статических файлов..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py collectstatic --noinput"

# 8. Перезапуск
echo ""
echo "🔄 Перезапуск сервиса..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "sudo systemctl restart estenomada-backend"

# 9. Тест email
echo ""
echo "🧪 Тестирование email..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py shell -c \"from django.core.mail import send_mail; from django.conf import settings; send_mail('✅ Деплой завершен - Este Nómada', 'Деплой личного кабинета успешно завершен!', settings.DEFAULT_FROM_EMAIL, [settings.EMAIL_HOST_USER], fail_silently=False); print('Тестовое письмо отправлено')\""

echo ""
echo "✅ Деплой завершён!"
echo ""
echo "📋 Что сделано:"
echo "   1. ✅ Код обновлен из бранча feature/personal-cabinet-cart"
echo "   2. ✅ Зависимости установлены"
echo "   3. ✅ Миграции применены"
echo "   4. ✅ Email настроен (info@nomadadeleste.com)"
echo "   5. ✅ ENCRYPTION_KEY сгенерирован"
echo "   6. ✅ Настройки доставки созданы"
echo "   7. ✅ Статика собрана"
echo "   8. ✅ Сервис перезапущен"
echo "   9. ✅ Тестовое письмо отправлено"
echo ""
echo "📧 Проверьте почту info@nomadadeleste.com"
echo "🌐 Проверьте: https://estenomada.es/ru/order"

