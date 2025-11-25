# Руководство по деплою Este Nómada

## Архитектура

Проект состоит из двух частей:

1. **Frontend** (Next.js) - `http://estenomada.es`
2. **Backend** (Django) - `http://api.estenomada.es` или `http://estenomada.es:8000`

## Деплой Backend (Django)

### Вариант 1: На том же сервере (one.com)

Если у тебя есть доступ к Node.js на one.com, можно запустить Django через systemd.

### Вариант 2: Отдельный VPS (рекомендуется)

Для production лучше использовать отдельный VPS для backend.

### Шаги деплоя

#### 1. Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Python и зависимостей
sudo apt install python3 python3-pip python3-venv mysql-client libmysqlclient-dev -y

# Установка Redis (для Celery)
sudo apt install redis-server -y
```

#### 2. Загрузка кода

```bash
# Создание директории
sudo mkdir -p /var/www/estenomada-backend
sudo chown $USER:$USER /var/www/estenomada-backend

# Загрузка файлов (через git или scp)
cd /var/www/estenomada-backend
# Загрузи файлы backend/
```

#### 3. Настройка

```bash
cd /var/www/estenomada-backend/backend

# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей
pip install -r requirements.txt

# Настройка .env
cp .env.example .env
nano .env  # Заполни все переменные
```

#### 4. Инициализация БД

```bash
# Применение миграций
python manage.py makemigrations
python manage.py migrate

# Инициализация данных
python scripts/init_db.py

# Создание администратора
python scripts/create_admin.py --username admin --password твой-пароль
```

#### 5. Запуск через Gunicorn

```bash
# Установка Gunicorn
pip install gunicorn

# Запуск
gunicorn este_nomada.wsgi:application --bind 0.0.0.0:8000 --workers 3
```

#### 6. Systemd Service

Создай `/etc/systemd/system/estenomada-backend.service`:

```ini
[Unit]
Description=Este Nomada Django Backend
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/estenomada-backend/backend
Environment="PATH=/var/www/estenomada-backend/backend/venv/bin"
ExecStart=/var/www/estenomada-backend/backend/venv/bin/gunicorn este_nomada.wsgi:application --bind 127.0.0.1:8000 --workers 3
Restart=always

[Install]
WantedBy=multi-user.target
```

Активация:

```bash
sudo systemctl daemon-reload
sudo systemctl enable estenomada-backend
sudo systemctl start estenomada-backend
sudo systemctl status estenomada-backend
```

#### 7. Celery Worker

Создай `/etc/systemd/system/estenomada-celery.service`:

```ini
[Unit]
Description=Este Nomada Celery Worker
After=network.target redis.service

[Service]
User=www-data
WorkingDirectory=/var/www/estenomada-backend/backend
Environment="PATH=/var/www/estenomada-backend/backend/venv/bin"
ExecStart=/var/www/estenomada-backend/backend/venv/bin/celery -A este_nomada worker --loglevel=info
Restart=always

[Install]
WantedBy=multi-user.target
```

Активация:

```bash
sudo systemctl enable estenomada-celery
sudo systemctl start estenomada-celery
```

#### 8. Nginx конфигурация

Создай `/etc/nginx/sites-available/estenomada-api`:

```nginx
server {
    listen 80;
    server_name api.estenomada.es;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /var/www/estenomada-backend/backend/staticfiles/;
    }

    location /media/ {
        alias /var/www/estenomada-backend/backend/media/;
    }
}
```

Активация:

```bash
sudo ln -s /etc/nginx/sites-available/estenomada-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Деплой Frontend (Next.js)

### 1. Обновление переменных окружения

В `.env.local` или `.env.production`:

```env
NEXT_PUBLIC_API_URL=https://api.estenomada.es/api
```

### 2. Сборка и деплой

```bash
npm run build
# Загрузи файлы из .next/ и public/ на сервер
```

## Проверка

1. **Backend API**: `https://api.estenomada.es/api/stories/`
2. **Django Admin**: `https://api.estenomada.es/admin/`
3. **Frontend**: `https://estenomada.es`

## Обновление

### Backend

```bash
cd /var/www/estenomada-backend/backend
source venv/bin/activate
git pull  # или загрузи новые файлы
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart estenomada-backend
sudo systemctl restart estenomada-celery
```

### Frontend

```bash
npm run build
# Загрузи обновленные файлы
```

## Мониторинг

### Логи Backend

```bash
sudo journalctl -u estenomada-backend -f
sudo journalctl -u estenomada-celery -f
```

### Логи Nginx

```bash
sudo tail -f /var/log/nginx/error.log
```

## Безопасность

1. ✅ Используй HTTPS (Let's Encrypt)
2. ✅ Настрой firewall (только 80, 443, 22)
3. ✅ Регулярно обновляй зависимости
4. ✅ Используй сильные пароли
5. ✅ Настрой резервное копирование БД
