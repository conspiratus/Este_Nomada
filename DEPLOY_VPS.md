# Быстрый деплой на VPS

## Подготовка

1. Убедитесь, что у вас есть доступ к VPS по SSH
2. Проверьте, что домен указывает на IP вашего VPS

## Автоматическая установка (рекомендуется)

```bash
# На VPS
curl -sSL https://raw.githubusercontent.com/your-repo/este-nomada/main/scripts/setup-vps.sh | bash
```

Или вручную:

```bash
chmod +x scripts/setup-vps.sh
./scripts/setup-vps.sh
```

## Ручная установка

Следуйте инструкциям в `VPS_SETUP.md`

## Деплой обновлений

```bash
# Локально
chmod +x scripts/vps-deploy.sh
./scripts/vps-deploy.sh estenomada@your-vps-ip
```

## Проверка работы

```bash
# На VPS
sudo systemctl status estenomada
sudo systemctl status nginx
curl http://localhost:3000
```

## Полезные команды

```bash
# Перезапуск приложения
sudo systemctl restart estenomada

# Просмотр логов
sudo journalctl -u estenomada -f

# Проверка конфигурации Nginx
sudo nginx -t
sudo systemctl reload nginx

# Обновление SSL сертификата
sudo certbot renew
```




