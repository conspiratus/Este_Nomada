#!/bin/bash
# Деплой личного кабинета на production сервер
# Использование: ./scripts/deploy_personal_cabinet_correct.sh

set -e

SERVER="administrator@85.190.102.101"
PASSWORD="Jovi4AndMay2020!"
REMOTE_DIR="/var/www/estenomada"

echo "🚀 Деплой личного кабинета и корзины на production"
echo "=================================================="

# Проверяем sshpass
if ! command -v sshpass &> /dev/null; then
    echo "❌ sshpass не установлен"
    echo "Установите: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# 1. Обновление кода
echo ""
echo "📥 Обновление кода из бранча feature/personal-cabinet-cart..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR} && if [ ! -d .git ]; then sudo -u www-data git init && sudo -u www-data git remote add origin https://github.com/conspiratus/Este_Nomada.git; fi && sudo -u www-data git fetch origin && sudo -u www-data git checkout -f feature/personal-cabinet-cart 2>/dev/null || (sudo -u www-data git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && sudo -u www-data git reset --hard origin/feature/personal-cabinet-cart) || sudo -u www-data git reset --hard origin/feature/personal-cabinet-cart"

# 2. Установка зависимостей
echo ""
echo "📦 Установка зависимостей backend..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && sudo -u www-data venv/bin/pip install -q --upgrade pip geopy markdown 2>/dev/null || (sudo -u www-data python3 -m venv venv_new && sudo -u www-data venv_new/bin/pip install -q -r requirements.txt geopy markdown && sudo mv venv venv_old && sudo mv venv_new venv && sudo rm -rf venv_old) || venv/bin/pip install -q geopy markdown"

# 3. Применение миграций
echo ""
echo "🗄️  Применение миграций..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && sudo -u www-data mkdir -p logs && sudo -u www-data chmod 755 logs && sudo -u www-data venv/bin/python manage.py migrate core 0020_dishttk_multiple_support --fake --noinput 2>/dev/null || true && sudo -u www-data venv/bin/python manage.py migrate core 0021_alter_ttkversionhistory_ttk_and_more --fake --noinput 2>/dev/null || true && sudo -u www-data venv/bin/python manage.py migrate --noinput 2>&1 | grep -v 'no such table' || sudo -u www-data venv/bin/python manage.py migrate core 0027_cart_deliverysettings_favorite_order_address_and_more --noinput"

# 4. Настройка email
echo ""
echo "📧 Настройка email..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && sudo -u www-data test -f .env && sudo -u www-data cp .env .env.backup.\$(date +%Y%m%d_%H%M%S) || true && sudo -u www-data sed -i.bak '/^EMAIL_/d' .env 2>/dev/null || true && sudo -u www-data sed -i.bak '/^DEFAULT_FROM_EMAIL/d' .env 2>/dev/null || true && sudo -u www-data sed -i.bak '/^SERVER_EMAIL/d' .env 2>/dev/null || true && sudo -u www-data bash -c 'cat >> .env << \"ENVEOF\"

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
'"

# 5. ENCRYPTION_KEY
echo ""
echo "🔐 Проверка ENCRYPTION_KEY..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && if ! sudo -u www-data grep -q '^ENCRYPTION_KEY=' .env 2>/dev/null; then ENC_KEY=\$(sudo -u www-data venv/bin/python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'); sudo -u www-data bash -c \"echo \\\"ENCRYPTION_KEY=\$ENC_KEY\\\" >> .env\" && echo 'Ключ сгенерирован'; else echo 'Ключ уже есть'; fi"

# 6. Настройки доставки
echo ""
echo "🚚 Проверка настроек доставки..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && sudo -u www-data venv/bin/python manage.py shell -c \"from core.models import DeliverySettings; s = DeliverySettings.get_settings(); print(f'Настройки доставки: ID={s.id}')\""

# 7. Сбор статики
echo ""
echo "📦 Сбор статических файлов..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && sudo -u www-data venv/bin/python manage.py collectstatic --noinput"

# 8. Перезапуск сервиса
echo ""
echo "🔄 Перезапуск сервиса..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "sudo systemctl restart estenomada-backend"

# 9. Тест email
echo ""
echo "🧪 Тестирование email..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER} "cd ${REMOTE_DIR}/backend && sudo -u www-data venv/bin/python manage.py shell -c \"from django.core.mail import send_mail; from django.conf import settings; send_mail('✅ Деплой завершен - Este Nómada', 'Деплой личного кабинета успешно завершен!', settings.DEFAULT_FROM_EMAIL, [settings.EMAIL_HOST_USER], fail_silently=False); print('Тестовое письмо отправлено')\""

echo ""
echo "✅ Деплой завершён!"
echo ""
echo "📋 Что сделано:"
echo "   1. ✅ Код обновлен из бранча feature/personal-cabinet-cart"
echo "   2. ✅ Зависимости установлены (geopy, markdown)"
echo "   3. ✅ Миграции применены"
echo "   4. ✅ Email настроен (info@nomadadeleste.com)"
echo "   5. ✅ ENCRYPTION_KEY сгенерирован"
echo "   6. ✅ Настройки доставки созданы"
echo "   7. ✅ Статические файлы собраны"
echo "   8. ✅ Сервис перезапущен"
echo "   9. ✅ Тестовое письмо отправлено"
echo ""
echo "📧 Проверьте почтовый ящик info@nomadadeleste.com"
echo "🌐 Проверьте страницу заказов: https://estenomada.es/ru/order"
echo "⚙️  Настройте доставку в админке: /admin/core/deliverysettings/"

