#!/bin/bash
# Запустите этот скрипт для автоматического деплоя
# Использование: bash RUN_DEPLOY_NOW.sh

set -e

SERVER="czjey8yl0_ssh@ssh.czjey8yl0.service.one"
PASSWORD="Drozdofil12345!"
REMOTE_DIR="/customers/d/9/4/czjey8yl0/webroots/17a5d75c"

echo "🚀 Автоматический деплой на production"
echo "======================================"
echo ""
echo "Подключение к серверу: $SERVER"
echo ""

# Проверяем наличие expect
if ! command -v expect &> /dev/null; then
    echo "❌ expect не установлен. Устанавливаю..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install expect
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y expect || sudo yum install -y expect
    else
        echo "❌ Не могу автоматически установить expect"
        echo "Установите expect вручную и запустите скрипт снова"
        exit 1
    fi
fi

# Выполняем деплой через expect
expect << EXPECT_SCRIPT
set timeout 1800
spawn ssh -p 22 -o StrictHostKeyChecking=no -o ConnectTimeout=30 $SERVER "cd $REMOTE_DIR && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart && chmod +x scripts/deploy_all_to_prod.sh && ./scripts/deploy_all_to_prod.sh"

expect {
    "password:" {
        send "$PASSWORD\r"
        exp_continue
    }
    "Password:" {
        send "$PASSWORD\r"
        exp_continue
    }
    "(yes/no" {
        send "yes\r"
        exp_continue
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        exp_continue
    }
    "Could not resolve hostname" {
        puts "\n❌ Ошибка: Не могу разрешить имя хоста"
        puts "Проверьте подключение к интернету и доступность сервера"
        exit 1
    }
    timeout {
        puts "\n❌ Таймаут подключения"
        exit 1
    }
    eof {
        catch wait result
        set exit_code [lindex \$result 3]
        if {\$exit_code != 0} {
            puts "\n❌ Ошибка при выполнении (код: \$exit_code)"
            exit \$exit_code
        }
        puts "\n✅ Деплой завершен успешно!"
        exit 0
    }
}
EXPECT_SCRIPT

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "🎉 Деплой завершен!"
    echo ""
    echo "📋 Что было сделано:"
    echo "   ✅ Код обновлен из бранча feature/personal-cabinet-cart"
    echo "   ✅ Зависимости установлены"
    echo "   ✅ Миграции применены"
    echo "   ✅ Email настроен (info@nomadadeleste.com)"
    echo "   ✅ Сервисы перезапущены"
    echo ""
    echo "📧 Проверьте почтовый ящик info@nomadadeleste.com - должно прийти тестовое письмо"
    echo "🌐 Проверьте сайт: https://estenomada.es/ru/order"
else
    echo ""
    echo "❌ Деплой завершился с ошибкой (код: $EXIT_CODE)"
    echo "Проверьте логи выше для деталей"
    exit $EXIT_CODE
fi

