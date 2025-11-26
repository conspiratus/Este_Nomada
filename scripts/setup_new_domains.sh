#!/bin/bash
# Скрипт для настройки новых доменов и получения SSL сертификатов

set -e

DOMAINS="nomadadeleste.es www.nomadadeleste.es nomadadeleste.com www.nomadadeleste.com"
EMAIL="admin@estenomada.es"
NGINX_CONF="/etc/nginx/sites-enabled/estenomada.production.conf"

echo "🔍 Проверяю DNS записи для новых доменов..."
for domain in $DOMAINS; do
    echo -n "  $domain: "
    IP=$(dig +short $domain | tail -1)
    if [ "$IP" = "85.190.102.101" ]; then
        echo "✅ OK ($IP)"
    else
        echo "❌ Неправильный IP ($IP, ожидается 85.190.102.101)"
        echo "⚠️  Настрой DNS записи перед продолжением!"
    fi
done

echo ""
read -p "Продолжить получение SSL сертификатов? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Отменено."
    exit 1
fi

echo ""
echo "🔐 Получаю SSL сертификаты для новых доменов..."
sudo certbot certonly --nginx \
    -d nomadadeleste.es \
    -d www.nomadadeleste.es \
    -d nomadadeleste.com \
    -d www.nomadadeleste.com \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --keep-until-expiring

echo ""
echo "✅ SSL сертификаты получены!"
echo ""
echo "📋 Проверь сертификаты:"
sudo ls -la /etc/letsencrypt/live/ | grep nomada

echo ""
echo "✅ Новые домены настроены!"
echo "🌐 Проверь:"
echo "   - https://nomadadeleste.es/ru"
echo "   - https://nomadadeleste.com/ru"


