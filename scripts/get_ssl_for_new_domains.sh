#!/bin/bash
# Скрипт для получения SSL сертификатов для новых доменов
# Использование: sudo ./get_ssl_for_new_domains.sh

set -e

DOMAINS="nomadadeleste.es www.nomadadeleste.es nomadadeleste.com www.nomadadeleste.com"
EMAIL="admin@estenomada.es"

echo "🔍 Проверяю DNS записи для новых доменов..."
ALL_DNS_OK=true
for domain in $DOMAINS; do
    IP=$(dig +short $domain | tail -1)
    if [ "$IP" = "85.190.102.101" ]; then
        echo "  ✅ $domain -> $IP"
    else
        echo "  ❌ $domain -> $IP (ожидается 85.190.102.101)"
        ALL_DNS_OK=false
    fi
done

if [ "$ALL_DNS_OK" = false ]; then
    echo ""
    echo "❌ Не все DNS записи настроены правильно!"
    echo "Настрой DNS записи перед продолжением:"
    echo "  - nomadadeleste.es -> A -> 85.190.102.101"
    echo "  - www.nomadadeleste.es -> CNAME -> nomadadeleste.es"
    echo "  - nomadadeleste.com -> A -> 85.190.102.101"
    echo "  - www.nomadadeleste.com -> CNAME -> nomadadeleste.com"
    exit 1
fi

echo ""
echo "✅ Все DNS записи настроены правильно!"
echo ""
echo "🛑 Останавливаю nginx для получения сертификата..."
sudo systemctl stop nginx

echo ""
echo "🔐 Расширяю существующий SSL сертификат для всех доменов (включая www)..."
sudo certbot certonly --standalone \
    --expand \
    -d estenomada.es \
    -d www.estenomada.es \
    -d nomadadeleste.es \
    -d www.nomadadeleste.es \
    -d nomadadeleste.com \
    -d www.nomadadeleste.com \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --preferred-challenges http

echo ""
echo "🚀 Запускаю nginx обратно..."
sudo systemctl start nginx

echo ""
echo "✅ SSL сертификат расширен для всех доменов!"
echo ""
echo "🌐 Проверь новые домены:"
echo "   - https://nomadadeleste.es/ru"
echo "   - https://nomadadeleste.com/ru"

