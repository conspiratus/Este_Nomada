#!/bin/bash
# Скрипт для установки и настройки почтового сервера на сервере one.com

set -e

echo "🔧 Установка почтового сервера для Este Nómada"
echo "================================================"

# Определяем ОС
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Не удалось определить ОС"
    exit 1
fi

echo "📦 Обнаружена ОС: $OS"

# Проверяем, установлен ли уже почтовый сервер
if command -v sendmail &> /dev/null || command -v postfix &> /dev/null || command -v exim &> /dev/null; then
    echo "✅ Почтовый сервер уже установлен"
    if command -v sendmail &> /dev/null; then
        echo "   Используется: sendmail"
    elif command -v postfix &> /dev/null; then
        echo "   Используется: postfix"
    elif command -v exim &> /dev/null; then
        echo "   Используется: exim"
    fi
    read -p "Переустановить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Используем существующий почтовый сервер"
        exit 0
    fi
fi

# Установка в зависимости от ОС
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    echo "📥 Установка postfix для Ubuntu/Debian..."
    
    # Обновляем пакеты
    sudo apt-get update
    
    # Устанавливаем postfix в режиме "Internet Site"
    echo "postfix postfix/mailname string estenomada.es" | sudo debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | sudo debconf-set-selections
    
    sudo apt-get install -y postfix mailutils
    
    echo "✅ Postfix установлен"
    
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    echo "📥 Установка postfix для CentOS/RHEL/Fedora..."
    
    if command -v dnf &> /dev/null; then
        sudo dnf install -y postfix mailx
    else
        sudo yum install -y postfix mailx
    fi
    
    echo "✅ Postfix установлен"
    
else
    echo "❌ Неподдерживаемая ОС: $OS"
    echo "Попробуйте установить postfix вручную"
    exit 1
fi

# Настройка postfix
echo "⚙️  Настройка postfix..."

# Создаем резервную копию конфига
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup

# Настраиваем базовые параметры
sudo postconf -e "myhostname = estenomada.es"
sudo postconf -e "mydomain = estenomada.es"
sudo postconf -e "myorigin = \$mydomain"
sudo postconf -e "inet_interfaces = loopback-only"
sudo postconf -e "inet_protocols = ipv4"

# Для one.com обычно нужно использовать relay через их SMTP
# Проверяем, есть ли информация о SMTP relay
if [ -f ~/.one_smtp_config ]; then
    source ~/.one_smtp_config
    if [ ! -z "$SMTP_RELAY" ]; then
        echo "📧 Настройка SMTP relay: $SMTP_RELAY"
        sudo postconf -e "relayhost = [$SMTP_RELAY]"
    fi
fi

# Запускаем и включаем postfix
sudo systemctl enable postfix
sudo systemctl restart postfix

# Проверяем статус
if sudo systemctl is-active --quiet postfix; then
    echo "✅ Postfix успешно запущен"
else
    echo "⚠️  Postfix установлен, но не запущен. Проверьте логи: sudo journalctl -u postfix"
fi

# Тест отправки письма
echo ""
echo "🧪 Тестирование отправки письма..."
read -p "Введите email для теста: " TEST_EMAIL

if [ ! -z "$TEST_EMAIL" ]; then
    echo "Тестовое письмо от Este Nómada" | mail -s "Test Email from Este Nómada" "$TEST_EMAIL"
    echo "✅ Тестовое письмо отправлено на $TEST_EMAIL"
    echo "   Проверьте папку 'Спам', если письмо не пришло"
fi

echo ""
echo "✅ Установка завершена!"
echo ""
echo "📝 Следующие шаги:"
echo "1. Настройте Django для использования локального sendmail:"
echo "   EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'"
echo "   EMAIL_HOST = 'localhost'"
echo "   EMAIL_PORT = 25"
echo "   EMAIL_USE_TLS = False"
echo ""
echo "2. Или используйте SMTP relay one.com (рекомендуется):"
echo "   Создайте файл ~/.one_smtp_config с содержимым:"
echo "   SMTP_RELAY=smtp.one.com"
echo "   Затем запустите этот скрипт снова"
echo ""
echo "3. Проверьте логи postfix: sudo journalctl -u postfix -f"

