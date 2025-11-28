#!/bin/bash
# Упрощенный деплой - все в одной команде через sshpass
# Использование: ./scripts/deploy_personal_cabinet_simple.sh

set -e

SERVER="czjey8yl0_ssh@ssh.czjey8yl0.service.one"
PASSWORD="Drozdofil12345!"
REMOTE_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"

echo "🚀 Деплой личного кабинета на production"
echo "=========================================="

# Проверяем sshpass
if ! command -v sshpass &> /dev/null; then
    echo "❌ sshpass не установлен"
    echo "Установите: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

echo ""
echo "📥 Обновление кода..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart"

echo ""
echo "📦 Установка зависимостей..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && pip install -q geopy markdown"

echo ""
echo "🗄️  Применение миграций..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py migrate --noinput"

echo ""
echo "📧 Настройка email..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && test -f .env && cp .env .env.backup.\$(date +%Y%m%d_%H%M%S) || true && sed -i.bak '/^EMAIL_/d' .env 2>/dev/null || true && sed -i.bak '/^DEFAULT_FROM_EMAIL/d' .env 2>/dev/null || true && sed -i.bak '/^SERVER_EMAIL/d' .env 2>/dev/null || true && cat >> .env << 'ENVEOF'

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

echo ""
echo "🔐 Проверка ENCRYPTION_KEY..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && if ! grep -q '^ENCRYPTION_KEY=' .env 2>/dev/null; then ENC_KEY=\$(python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'); echo \"ENCRYPTION_KEY=\$ENC_KEY\" >> .env && echo 'Ключ сгенерирован'; else echo 'Ключ уже есть'; fi"

echo ""
echo "📦 Сбор статики..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py collectstatic --noinput"

echo ""
echo "🔄 Перезапуск сервиса..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "sudo systemctl restart estenomada-backend"

echo ""
echo "🧪 Тест email..."
sshpass -p "$PASSWORD" ssh -p 22 -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && source venv/bin/activate && python manage.py shell -c \"from django.core.mail import send_mail; from django.conf import settings; send_mail('✅ Деплой завершен', 'Деплой успешно завершен!', settings.DEFAULT_FROM_EMAIL, [settings.EMAIL_HOST_USER], fail_silently=False); print('Письмо отправлено')\""

echo ""
echo "✅ Деплой завершён!"
echo ""
echo "📧 Проверьте почту info@nomadadeleste.com"
echo "🌐 Проверьте: https://estenomada.es/ru/order"

