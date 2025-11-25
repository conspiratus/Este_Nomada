# 🚀 Деплой в Production

Полное руководство по деплою проекта Este Nómada в production окружение.

## 📋 Архитектура

Проект состоит из:
- **Frontend**: Next.js 14 (порт 3000)
- **Backend**: Django 5.0 + DRF (порт 8000)
- **Database**: MySQL 8.0
- **Cache/Queue**: Redis
- **Task Queue**: Celery (worker + beat)
- **Web Server**: Nginx (reverse proxy)

## 🔧 Предварительные требования

### На сервере должны быть установлены:

1. **Node.js 18+**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **Python 3.11+**
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip python3-venv -y
   ```

3. **MySQL 8.0**
   ```bash
   sudo apt install mysql-server -y
   sudo mysql_secure_installation
   ```

4. **Redis**
   ```bash
   sudo apt install redis-server -y
   sudo systemctl enable redis-server
   sudo systemctl start redis-server
   ```

5. **Nginx**
   ```bash
   sudo apt install nginx -y
   ```

6. **Certbot (для SSL)**
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   ```

## 📝 Шаг 1: Подготовка переменных окружения

### Backend (.env.production)

Создай файл `backend/.env.production`:

```bash
cp backend/.env.production.example backend/.env.production
nano backend/.env.production
```

Заполни все переменные:
- `SECRET_KEY` - сгенерируй случайную строку (минимум 50 символов)
- `DB_PASSWORD` - пароль для MySQL
- `CORS_ALLOWED_ORIGINS` - домены фронтенда
- API ключи для Telegram, OpenAI, Instagram

### Frontend (.env.production)

Создай файл `.env.production`:

```bash
cp .env.production.example .env.production
nano .env.production
```

Укажи:
- `NEXT_PUBLIC_API_URL` - URL Django API (например, `https://api.estenomada.es/api`)
- `NEXT_PUBLIC_BASE_URL` - URL фронтенда (например, `https://estenomada.es`)

## 🗄️ Шаг 2: Настройка базы данных

### Создание базы данных MySQL

```bash
sudo mysql -u root -p
```

```sql
CREATE DATABASE czjey8yl0_estenomada CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'czjey8yl0_estenomada'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON czjey8yl0_estenomada.* TO 'czjey8yl0_estenomada'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 🚀 Шаг 3: Деплой

### Вариант 1: Автоматический деплой (рекомендуется)

```bash
# Локально
./scripts/deploy-production.sh user@server_ip
```

Скрипт автоматически:
1. Соберёт фронтенд
2. Создаст архив
3. Загрузит на сервер
4. Распакует и настроит всё окружение

### Вариант 2: Ручной деплой

#### 3.1. Сборка фронтенда

```bash
npm run build
```

#### 3.2. Загрузка файлов на сервер

```bash
# Создание архива
tar -czf deploy.tar.gz \
    .next public package*.json next.config.mjs server.js \
    tsconfig.json middleware.ts i18n.ts lib app components \
    types messages backend nginx systemd scripts

# Загрузка
scp deploy.tar.gz user@server:/tmp/
```

#### 3.3. Настройка на сервере

```bash
ssh user@server

# Распаковка
sudo mkdir -p /var/www/estenomada
cd /tmp
sudo tar -xzf deploy.tar.gz -C /var/www/estenomada
sudo chown -R www-data:www-data /var/www/estenomada

# Запуск скрипта настройки
sudo bash /var/www/estenomada/scripts/setup-production.sh
```

## 🔐 Шаг 4: Настройка SSL (Let's Encrypt)

```bash
# Для основного домена
sudo certbot --nginx -d estenomada.es -d www.estenomada.es

# Для API поддомена
sudo certbot --nginx -d api.estenomada.es

# Автообновление
sudo certbot renew --dry-run
```

## ⚙️ Шаг 5: Настройка systemd сервисов

Сервисы уже настроены скриптом, но можно проверить:

```bash
# Проверка статуса
sudo systemctl status estenomada-backend
sudo systemctl status estenomada-frontend
sudo systemctl status estenomada-celery
sudo systemctl status estenomada-celery-beat

# Логи
sudo journalctl -u estenomada-backend -f
sudo journalctl -u estenomada-frontend -f
```

## 🗄️ Шаг 6: Инициализация базы данных

```bash
cd /var/www/estenomada/backend
source venv/bin/activate

# Применение миграций
python manage.py migrate

# Создание суперпользователя
python manage.py createsuperuser

# Импорт переводов (опционально)
python scripts/import_translations.py
```

## 🔄 Шаг 7: Обновление (redeploy)

Для обновления проекта:

```bash
# Локально
./scripts/deploy-production.sh user@server_ip
```

Или вручную:

```bash
# На сервере
cd /var/www/estenomada/backend
source venv/bin/activate
git pull  # или загрузи новые файлы
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart estenomada-backend
sudo systemctl restart estenomada-frontend
```

## 🐳 Альтернатива: Docker Compose

Если предпочитаешь Docker:

```bash
# На сервере
cd /var/www/estenomada

# Создай .env файлы
cp backend/.env.production.example backend/.env.production
cp .env.production.example .env.production

# Запуск
docker-compose -f docker-compose.production.yml up -d

# Проверка
docker-compose -f docker-compose.production.yml ps
docker-compose -f docker-compose.production.yml logs -f
```

## 📊 Мониторинг

### Логи

```bash
# Django
tail -f /var/www/estenomada/backend/logs/django.log

# Nginx
sudo tail -f /var/log/nginx/estenomada_access.log
sudo tail -f /var/log/nginx/estenomada_error.log

# Systemd
sudo journalctl -u estenomada-backend -f
sudo journalctl -u estenomada-frontend -f
```

### Проверка здоровья

```bash
# Frontend
curl https://estenomada.es

# Backend API
curl https://api.estenomada.es/api/menu/

# Health check
curl https://api.estenomada.es/api/health/
```

## 🔒 Безопасность

1. **Firewall**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

2. **Fail2Ban** (опционально)
   ```bash
   sudo apt install fail2ban -y
   ```

3. **Регулярные обновления**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## 🆘 Troubleshooting

### Проблема: Сервисы не запускаются

```bash
# Проверь логи
sudo journalctl -u estenomada-backend -n 50
sudo journalctl -u estenomada-frontend -n 50

# Проверь права доступа
sudo chown -R www-data:www-data /var/www/estenomada

# Проверь переменные окружения
sudo systemctl cat estenomada-backend
```

### Проблема: База данных не подключается

```bash
# Проверь подключение
mysql -u czjey8yl0_estenomada -p czjey8yl0_estenomada

# Проверь настройки в .env.production
cat /var/www/estenomada/backend/.env.production
```

### Проблема: Nginx не проксирует

```bash
# Проверь конфигурацию
sudo nginx -t

# Проверь логи
sudo tail -f /var/log/nginx/error.log

# Перезагрузи Nginx
sudo systemctl reload nginx
```

## 📞 Поддержка

При возникновении проблем проверь:
1. Логи сервисов
2. Права доступа к файлам
3. Переменные окружения
4. Статус сервисов (systemctl status)
5. Подключение к базе данных
6. Конфигурацию Nginx

---

**Готово!** 🎉 Проект должен быть доступен по адресам:
- Frontend: `https://estenomada.es`
- Backend API: `https://api.estenomada.es/api`
- Admin: `https://api.estenomada.es/admin`




