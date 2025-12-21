# 🚀 Инструкция по настройке второго сайта "Temis" на том же сервере

## 📋 Обзор

Эта инструкция описывает, как настроить второй сайт "Temis" на том же сервере, где уже работает "Este Nómada", чтобы оба сайта работали параллельно без конфликтов.

## 🎯 Архитектура

### Текущая конфигурация (Este Nómada):
- **Директория**: `/var/www/estenomada`
- **Frontend порт**: `3000`
- **Backend порт**: `8000`
- **Systemd сервисы**: `estenomada-frontend`, `estenomada-backend`
- **Домен**: `estenomada.es`

### Новая конфигурация (Temis):
- **Директория**: `/var/www/temis`
- **Frontend порт**: `3001` ⚠️ **ВАЖНО: другой порт!**
- **Backend порт**: `8001` ⚠️ **ВАЖНО: другой порт!**
- **Systemd сервисы**: `temis-frontend`, `temis-backend`
- **Домен**: `temis.es` (или другой домен)

---

## 📝 Шаг 1: Подготовка на сервере

### 1.1. Создание директорий

```bash
# Подключись к серверу
ssh administrator@85.190.102.101

# Создай директорию для Temis
sudo mkdir -p /var/www/temis
sudo chown -R www-data:www-data /var/www/temis
```

### 1.2. Проверка свободных портов

```bash
# Проверь, что порты 3001 и 8001 свободны
sudo netstat -tlnp | grep -E ':(3001|8001)'

# Если порты заняты, выбери другие (например, 3002 и 8002)
```

### 1.3. Создание systemd сервисов

#### Frontend сервис (`/etc/systemd/system/temis-frontend.service`):

```bash
sudo nano /etc/systemd/system/temis-frontend.service
```

Вставь следующее содержимое:

```ini
[Unit]
Description=Temis Next.js Frontend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/temis
Environment="NODE_ENV=production"
Environment="PORT=3001"
Environment="HOSTNAME=0.0.0.0"
Environment="NEXT_TELEMETRY_DISABLED=1"
EnvironmentFile=/var/www/temis/.env.production
ExecStart=/usr/bin/node /var/www/temis/server.js
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=10
LimitNOFILE=65536
MemoryLimit=2G

[Install]
WantedBy=multi-user.target
```

#### Backend сервис (`/etc/systemd/system/temis-backend.service`):

```bash
sudo nano /etc/systemd/system/temis-backend.service
```

Вставь следующее содержимое:

```ini
[Unit]
Description=Temis Django Backend
After=network.target mysql.service

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/var/www/temis/backend
Environment="PATH=/var/www/temis/backend/venv/bin:/usr/bin:/bin"
EnvironmentFile=/var/www/temis/backend/.env.production
ExecStart=/var/www/temis/backend/venv/bin/gunicorn \
    --bind 0.0.0.0:8001 \
    --workers 4 \
    --timeout 120 \
    --access-logfile /var/www/temis/backend/logs/access.log \
    --error-logfile /var/www/temis/backend/logs/error.log \
    temis.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**⚠️ ВАЖНО:** Замени `temis.wsgi:application` на правильное имя твоего Django проекта!

#### Активация сервисов:

```bash
# Перезагрузи systemd
sudo systemctl daemon-reload

# Включи автозапуск (но пока не запускай, так как файлов еще нет)
sudo systemctl enable temis-frontend
sudo systemctl enable temis-backend
```

---

## 🌐 Шаг 2: Настройка Nginx

### 2.1. Создание конфигурации Nginx

Создай файл конфигурации для Temis:

```bash
sudo nano /etc/nginx/sites-available/temis
```

Вставь следующее содержимое (замени `temis.es` на твой домен):

```nginx
# HTTP -> HTTPS редирект
server {
    listen 80;
    listen [::]:80;
    server_name temis.es www.temis.es;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Редирект на HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# Frontend (Next.js) - HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name temis.es www.temis.es;

    # SSL сертификаты (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/temis.es/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/temis.es/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Логи
    access_log /var/log/nginx/temis_access.log;
    error_log /var/log/nginx/temis_error.log;

    # Максимальный размер загружаемых файлов
    client_max_body_size 20M;

    # Статические файлы Next.js
    location /_next/static/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable" always;
    }

    # HTML страницы из _next - не кешируем
    location /_next/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_no_cache 1;
        proxy_cache_bypass 1;
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    }

    # API запросы
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        add_header Cache-Control "no-cache" always;
    }

    # Backend API (если используешь отдельный Django API)
    location /backend-api/ {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Все остальные запросы (HTML страницы)
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    }
}
```

### 2.2. Активация конфигурации

```bash
# Создай символическую ссылку
sudo ln -s /etc/nginx/sites-available/temis /etc/nginx/sites-enabled/temis

# Проверь конфигурацию
sudo nginx -t

# Если все ОК, перезагрузи Nginx
sudo systemctl reload nginx
```

### 2.3. Настройка SSL (Let's Encrypt)

#### 2.3.1. Проверка DNS записей

**⚠️ ВАЖНО:** Перед получением SSL сертификата убедись, что DNS записи настроены правильно!

```bash
# Проверь DNS записи для домена temis.es
dig +short temis.es
dig +short www.temis.es

# Оба должны указывать на IP сервера: 85.190.102.101
# Если DNS записи не настроены, настрой их в панели управления доменом:
# - temis.es -> A запись -> 85.190.102.101
# - www.temis.es -> CNAME запись -> temis.es (или A запись -> 85.190.102.101)
```

#### 2.3.2. Установка Certbot (если еще не установлен)

```bash
# Проверь, установлен ли certbot
which certbot

# Если не установлен, установи его:
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Проверь версию
certbot --version
```

#### 2.3.3. Получение SSL сертификата

**Вариант 1: Автоматическая настройка через Nginx (рекомендуется)**

```bash
# Certbot автоматически настроит Nginx конфигурацию
sudo certbot --nginx -d temis.es -d www.temis.es

# Во время установки certbot спросит:
# - Email для уведомлений (укажи свой email)
# - Согласие с условиями (нажми Y)
# - Редирект HTTP на HTTPS (рекомендуется выбрать 2 - Redirect)
```

**Вариант 2: Ручная настройка (если нужно больше контроля)**

```bash
# Сначала получи сертификат без изменения Nginx
sudo certbot certonly --nginx -d temis.es -d www.temis.es

# Затем вручную обнови конфигурацию Nginx (уже сделано выше в разделе 2.1)
# И перезагрузи Nginx
sudo systemctl reload nginx
```

**Вариант 3: Standalone режим (если Nginx не запущен)**

```bash
# Останови Nginx
sudo systemctl stop nginx

# Получи сертификат в standalone режиме
sudo certbot certonly --standalone -d temis.es -d www.temis.es

# Запусти Nginx обратно
sudo systemctl start nginx
```

#### 2.3.4. Проверка сертификата

```bash
# Проверь список всех сертификатов
sudo certbot certificates

# Должен быть виден сертификат для temis.es с путем:
# /etc/letsencrypt/live/temis.es/fullchain.pem

# Проверь файлы сертификата
sudo ls -la /etc/letsencrypt/live/temis.es/

# Должны быть файлы:
# - cert.pem (сертификат)
# - chain.pem (промежуточный сертификат)
# - fullchain.pem (полная цепочка)
# - privkey.pem (приватный ключ)
```

#### 2.3.5. Проверка работы HTTPS

```bash
# Проверь, что сайт доступен по HTTPS
curl -I https://temis.es

# Должен вернуть статус 200 или 301/302

# Проверь сертификат через openssl
echo | openssl s_client -servername temis.es -connect temis.es:443 2>/dev/null | openssl x509 -noout -dates

# Проверь в браузере
# Открой https://temis.es и убедись, что:
# - Нет предупреждений о безопасности
# - В адресной строке есть замочек 🔒
# - Сертификат выдан Let's Encrypt
```

#### 2.3.6. Настройка автообновления сертификата

Let's Encrypt сертификаты действительны 90 дней. Certbot автоматически настраивает автообновление через systemd timer.

```bash
# Проверь, что автообновление настроено
sudo systemctl status certbot.timer

# Должен быть активен (active)

# Проверь расписание обновления
sudo systemctl list-timers | grep certbot

# Тестовый запуск обновления (dry-run)
sudo certbot renew --dry-run

# Если все ОК, увидишь сообщение:
# "The dry run was successful."
```

#### 2.3.7. Обновление Nginx конфигурации после получения сертификата

После получения сертификата certbot может автоматически обновить Nginx конфигурацию. Проверь файл:

```bash
# Проверь, что конфигурация обновлена
sudo cat /etc/nginx/sites-available/temis | grep ssl_certificate

# Должны быть строки:
# ssl_certificate /etc/letsencrypt/live/temis.es/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/temis.es/privkey.pem;

# Если certbot не обновил конфигурацию автоматически,
# убедись, что в конфигурации (раздел 2.1) указаны правильные пути
```

#### 2.3.8. Решение проблем с SSL

**Проблема: "Failed to obtain certificate"**

```bash
# Проверь DNS записи
dig +short temis.es

# Проверь, что порт 80 открыт
sudo netstat -tlnp | grep :80

# Проверь, что Nginx слушает на порту 80
sudo nginx -t
sudo systemctl status nginx

# Проверь логи certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

**Проблема: "Domain does not point to this server"**

```bash
# Убедись, что DNS записи указывают на правильный IP
dig +short temis.es
# Должен вернуть: 85.190.102.101

# Подожди распространения DNS (может занять до 48 часов, обычно несколько минут)
# Проверь через разные DNS серверы:
dig @8.8.8.8 +short temis.es
dig @1.1.1.1 +short temis.es
```

**Проблема: "Too many requests"**

Let's Encrypt имеет лимит на количество запросов сертификатов для одного домена (50 в неделю).

```bash
# Проверь, сколько сертификатов уже запрошено
sudo certbot certificates

# Если лимит превышен, подожди неделю или используй существующий сертификат
```

**Проблема: Сертификат не обновляется автоматически**

```bash
# Включи и запусти timer для автообновления
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Проверь статус
sudo systemctl status certbot.timer

# Проверь логи
sudo journalctl -u certbot.timer -n 50
```

#### 2.3.9. Дополнительные настройки безопасности

После получения SSL сертификата можно добавить дополнительные заголовки безопасности в Nginx конфигурацию (уже включены в конфигурацию из раздела 2.1):

```nginx
# Security headers (уже добавлены в конфигурацию выше)
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

#### 2.3.10. Проверка срока действия сертификата

```bash
# Проверь дату истечения сертификата
sudo certbot certificates | grep -A 5 "temis.es"

# Или через openssl
echo | openssl s_client -servername temis.es -connect temis.es:443 2>/dev/null | openssl x509 -noout -enddate

# Certbot автоматически обновит сертификат за 30 дней до истечения
```

---

## 🔐 Шаг 3: Настройка GitHub Actions для проекта Temis

### 3.1. Создание workflow файлов

В репозитории проекта Temis создай директорию `.github/workflows/` и файлы:

#### `ci.yml` (аналогично Este Nómada):

```yaml
name: CI

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  frontend:
    name: Frontend (Next.js)
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linter
        run: npm run lint
      
      - name: Build
        run: npm run build
        env:
          NODE_ENV: production

  backend:
    name: Backend (Django)
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
          cache-dependency-path: './backend/requirements.txt'
      
      - name: Install dependencies
        working-directory: ./backend
        run: |
          python -m pip install --upgrade pip
          pip install --no-cache-dir -r requirements.txt
      
      - name: Check for pending migrations
        working-directory: ./backend
        run: |
          python manage.py makemigrations --check --dry-run
        env:
          DJANGO_SETTINGS_MODULE: temis.settings
          USE_SQLITE: 'True'
      
      - name: Run Django check
        working-directory: ./backend
        run: |
          python manage.py check
        env:
          DJANGO_SETTINGS_MODULE: temis.settings
          USE_SQLITE: 'True'
```

#### `deploy.yml` (адаптированный для Temis):

```yaml
name: Deploy Temis to Production

on:
  workflow_run:
    workflows: ["CI"]
    types:
      - completed
  workflow_dispatch:

concurrency:
  group: deploy-temis-production
  cancel-in-progress: false

jobs:
  deploy:
    name: Deploy Temis to Production
    runs-on: ubuntu-latest
    if: |
      github.event.workflow_run.conclusion == 'success' &&
      (github.event.workflow_run.head_branch == 'main' || github.event.workflow_run.head_branch == 'master')
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_branch }}
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install frontend dependencies
        run: npm ci
      
      - name: Build frontend
        run: npm run build
        env:
          NODE_ENV: production
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'
          cache-dependency-path: './backend/requirements.txt'
      
      - name: Install Python dependencies
        working-directory: ./backend
        run: |
          python -m pip install --upgrade pip
          pip install --no-cache-dir -r requirements.txt
      
      - name: Check Django
        working-directory: ./backend
        run: python manage.py check
        env:
          DJANGO_SETTINGS_MODULE: temis.settings
          USE_SQLITE: 'True'
      
      - name: Create deployment archive
        run: |
          echo "📦 Creating deployment archive..."
          tar -czf deploy.tar.gz \
            .next \
            public \
            package.json \
            package-lock.json \
            next.config.mjs \
            server.js \
            tsconfig.json \
            middleware.ts \
            i18n.ts \
            lib \
            app \
            components \
            types \
            messages \
            backend \
            nginx \
            systemd \
            scripts \
            prerender-manifest.json
          echo "✅ Archive created: $(du -h deploy.tar.gz | cut -f1)"
      
      - name: Check secrets
        run: |
          if [ -z "${{ secrets.PROD_SERVER_HOST }}" ]; then
            echo "❌ Ошибка: PROD_SERVER_HOST не настроен"
            exit 1
          fi
          if [ -z "${{ secrets.PROD_SERVER_USER }}" ]; then
            echo "❌ Ошибка: PROD_SERVER_USER не настроен"
            exit 1
          fi
          if [ -z "${{ secrets.PROD_SERVER_PASSWORD }}" ]; then
            echo "❌ Ошибка: PROD_SERVER_PASSWORD не настроен"
            exit 1
          fi
          echo "✅ Все секреты настроены"
      
      - name: Install sshpass
        run: |
          sudo apt-get update
          sudo apt-get install -y sshpass
      
      - name: Upload archive via SCP
        env:
          SSHPASS: ${{ secrets.PROD_SERVER_PASSWORD }}
        run: |
          echo "📤 Uploading deploy.tar.gz to server..."
          sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            deploy.tar.gz ${{ secrets.PROD_SERVER_USER }}@${{ secrets.PROD_SERVER_HOST }}:/tmp/temis-deploy.tar.gz
      
      - name: Extract and deploy on server
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.PROD_SERVER_HOST }}
          username: ${{ secrets.PROD_SERVER_USER }}
          password: ${{ secrets.PROD_SERVER_PASSWORD }}
          port: 22
          timeout: 300s
          debug: true
          script: |
            set -e
            
            DEPLOY_DIR="/var/www/temis"
            BACKEND_DIR="$DEPLOY_DIR/backend"
            FRONTEND_DIR="$DEPLOY_DIR"
            
            echo "🚀 Начинаем деплой Temis..."
            
            # Создаем бэкап
            if [ -d "$DEPLOY_DIR" ]; then
              echo "📦 Создаю бэкап..."
              sudo tar -czf /tmp/temis-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C $DEPLOY_DIR . 2>/dev/null || true
            fi
            
            # Распаковываем новый код
            echo "📥 Распаковываем новый код..."
            sudo mkdir -p $DEPLOY_DIR
            cd /tmp
            sudo tar -xzf temis-deploy.tar.gz -C $DEPLOY_DIR
            sudo rm temis-deploy.tar.gz
            echo "✅ Код распакован"
            
            # Устанавливаем права
            echo "🔐 Устанавливаем права..."
            sudo chown -R www-data:www-data $DEPLOY_DIR
            sudo find $DEPLOY_DIR -type d -exec chmod 755 {} \;
            sudo find $DEPLOY_DIR -type f -exec chmod 644 {} \;
            sudo chmod +x $DEPLOY_DIR/scripts/*.sh 2>/dev/null || true
            
            # Backend: устанавливаем зависимости
            echo "📦 Устанавливаем Python зависимости..."
            cd $BACKEND_DIR
            
            PYTHON_CMD=$(which python3.12 || which python3 || which python)
            echo "Используем Python: $PYTHON_CMD"
            
            # Создаем venv
            echo "Создаю виртуальное окружение..."
            sudo rm -rf venv
            sudo -u www-data $PYTHON_CMD -m venv venv
            sudo chmod +x venv/bin/* 2>/dev/null || true
            sudo chown -R www-data:www-data venv
            
            # Устанавливаем зависимости
            echo "Устанавливаю зависимости..."
            sudo -u www-data venv/bin/python -m pip install --upgrade pip
            sudo -u www-data venv/bin/python -m pip install --no-cache-dir -r requirements.txt
            echo "✅ Зависимости установлены"
            
            # Применяем миграции
            echo "🗄️  Применяем миграции Django..."
            set +e
            sudo -u www-data venv/bin/python manage.py migrate --noinput 2>&1 || echo "⚠️  Ошибка миграций"
            set -e
            
            # Собираем статику
            echo "📦 Собираем статику Django..."
            sudo -u www-data venv/bin/python manage.py collectstatic --noinput || echo "⚠️  Ошибка collectstatic"
            
            # Frontend: устанавливаем зависимости
            echo "📦 Устанавливаем Node.js зависимости..."
            cd $FRONTEND_DIR
            
            if [ ! -d ".next" ]; then
              echo "⚠️  .next директория не найдена!"
              exit 1
            fi
            
            sudo rm -rf node_modules package-lock.json 2>/dev/null || true
            sudo -u www-data npm install || sudo npm install
            sudo chown -R www-data:www-data node_modules package-lock.json 2>/dev/null || true
            echo "✅ Зависимости установлены"
            
            # Перезапускаем сервисы
            echo "🔄 Перезапускаем сервисы..."
            set +e
            
            if systemctl list-unit-files | grep -q temis-backend; then
              sudo systemctl restart temis-backend
              echo "✅ Backend перезапущен"
            fi
            
            if systemctl list-unit-files | grep -q temis-frontend; then
              sudo systemctl restart temis-frontend
              echo "✅ Frontend перезапущен"
            fi
            set -e
            
            # Перезагружаем Nginx
            echo "🔄 Перезагружаем Nginx..."
            sudo nginx -t && sudo systemctl reload nginx
            echo "✅ Nginx перезагружен"
            
            # Проверяем статус
            echo "📊 Проверяем статус сервисов..."
            sudo systemctl status temis-backend --no-pager -l | head -10 || true
            sudo systemctl status temis-frontend --no-pager -l | head -10 || true
            
            echo "✅ Деплой Temis завершен!"
      
      - name: Cleanup
        if: always()
        run: rm -f deploy.tar.gz
```

### 3.2. Настройка GitHub Secrets

В настройках репозитория Temis добавь секреты:

1. Перейди в **Settings** → **Secrets and variables** → **Actions**
2. Добавь секреты (можно использовать те же, что и для Este Nómada, так как это тот же сервер):

   - **`PROD_SERVER_HOST`**: `85.190.102.101`
   - **`PROD_SERVER_USER`**: `administrator`
   - **`PROD_SERVER_PASSWORD`**: `твой_пароль`

---

## ✅ Шаг 4: Проверка и тестирование

### 4.1. Проверка портов

```bash
# На сервере проверь, что порты используются правильно
sudo netstat -tlnp | grep -E ':(3000|3001|8000|8001)'

# Должно быть:
# 3000 - estenomada-frontend
# 3001 - temis-frontend
# 8000 - estenomada-backend
# 8001 - temis-backend
```

### 4.2. Проверка сервисов

```bash
# Проверь статус всех сервисов
sudo systemctl status estenomada-frontend
sudo systemctl status estenomada-backend
sudo systemctl status temis-frontend
sudo systemctl status temis-backend

# Проверь логи
sudo journalctl -u temis-frontend -n 50
sudo journalctl -u temis-backend -n 50
```

### 4.3. Проверка Nginx

```bash
# Проверь конфигурацию
sudo nginx -t

# Проверь, что оба сайта активны
sudo nginx -T | grep -E 'server_name|listen'

# Проверь логи
sudo tail -f /var/log/nginx/temis_access.log
sudo tail -f /var/log/nginx/temis_error.log
```

### 4.4. Тестирование в браузере

- Открой `https://estenomada.es` - должен работать Este Nómada
- Открой `https://temis.es` - должен работать Temis

---

## 🔧 Важные замечания

### Изоляция проектов

1. **Разные директории**: Каждый проект в своей директории (`/var/www/estenomada` и `/var/www/temis`)
2. **Разные порты**: Каждый проект использует свои порты
3. **Разные systemd сервисы**: Каждый проект имеет свои сервисы
4. **Разные Nginx конфиги**: Каждый проект имеет свой конфиг Nginx
5. **Разные базы данных**: Используй разные БД для каждого проекта

### Переменные окружения

Убедись, что в `.env.production` каждого проекта указаны правильные порты:

**Este Nómada** (`/var/www/estenomada/.env.production`):
```env
PORT=3000
NEXT_PUBLIC_API_URL=https://api.estenomada.es
```

**Temis** (`/var/www/temis/.env.production`):
```env
PORT=3001
NEXT_PUBLIC_API_URL=https://api.temis.es
```

### Базы данных

Если используешь MySQL, создай отдельную БД для Temis:

```bash
# Подключись к MySQL
sudo mysql -u root -p

# Создай БД для Temis
CREATE DATABASE temis_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'temis_user'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON temis_db.* TO 'temis_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Мониторинг ресурсов

Следи за использованием ресурсов:

```bash
# Проверь использование памяти
free -h

# Проверь использование диска
df -h

# Проверь нагрузку на CPU
top
```

---

## 🚨 Решение проблем

### Проблема: Порт уже занят

```bash
# Найди процесс, использующий порт
sudo lsof -i :3001

# Останови процесс или измени порт в конфигурации
```

### Проблема: Сервис не запускается

```bash
# Проверь логи
sudo journalctl -u temis-frontend -n 100
sudo journalctl -u temis-backend -n 100

# Проверь права доступа
sudo ls -la /var/www/temis
sudo chown -R www-data:www-data /var/www/temis
```

### Проблема: Nginx не проксирует запросы

```bash
# Проверь конфигурацию
sudo nginx -t

# Проверь, что сервисы запущены
sudo systemctl status temis-frontend
sudo systemctl status temis-backend

# Проверь логи Nginx
sudo tail -f /var/log/nginx/temis_error.log
```

---

## 📚 Дополнительные ресурсы

- [Nginx документация](https://nginx.org/en/docs/)
- [Systemd документация](https://www.freedesktop.org/software/systemd/man/)
- [Let's Encrypt документация](https://letsencrypt.org/docs/)

---

## ✅ Чеклист настройки

### Подготовка сервера
- [ ] Создана директория `/var/www/temis`
- [ ] Установлены правильные права доступа (`www-data:www-data`)
- [ ] Проверены свободные порты (3001, 8001)
- [ ] Созданы systemd сервисы (`temis-frontend`, `temis-backend`)
- [ ] Systemd сервисы включены в автозапуск (`systemctl enable`)

### Настройка Nginx
- [ ] Создан Nginx конфиг `/etc/nginx/sites-available/temis`
- [ ] Создана символическая ссылка в `/etc/nginx/sites-enabled/`
- [ ] Проверена конфигурация Nginx (`nginx -t`)
- [ ] Nginx перезагружен (`systemctl reload nginx`)

### Настройка DNS
- [ ] Настроена A запись для `temis.es` → `85.190.102.101`
- [ ] Настроена CNAME или A запись для `www.temis.es`
- [ ] Проверено распространение DNS (`dig +short temis.es`)
- [ ] DNS записи указывают на правильный IP

### Настройка SSL сертификата
- [ ] Установлен Certbot (`apt install certbot python3-certbot-nginx`)
- [ ] Получен SSL сертификат для `temis.es` и `www.temis.es`
- [ ] Проверено наличие файлов сертификата в `/etc/letsencrypt/live/temis.es/`
- [ ] Проверена работа HTTPS (`curl -I https://temis.es`)
- [ ] Проверен срок действия сертификата (`certbot certificates`)
- [ ] Настроено автообновление сертификата (`systemctl status certbot.timer`)
- [ ] Выполнен тест обновления (`certbot renew --dry-run`)
- [ ] Сайт открывается по HTTPS без предупреждений в браузере

### Настройка GitHub Actions
- [ ] Создана директория `.github/workflows/` в репозитории Temis
- [ ] Создан файл `ci.yml` для проверки кода
- [ ] Создан файл `deploy.yml` для автоматического деплоя
- [ ] Настроены GitHub Secrets:
  - [ ] `PROD_SERVER_HOST` = `85.190.102.101`
  - [ ] `PROD_SERVER_USER` = `administrator`
  - [ ] `PROD_SERVER_PASSWORD` = `Jovi4AndMay2020!`
- [ ] Протестирован CI pipeline (push в репозиторий)
- [ ] Протестирован деплой pipeline

### Настройка базы данных
- [ ] Создана отдельная БД для Temis (`CREATE DATABASE temis_db`)
- [ ] Создан пользователь БД для Temis (`CREATE USER 'temis_user'`)
- [ ] Настроены права доступа для пользователя БД
- [ ] Проверено подключение к БД

### Настройка переменных окружения
- [ ] Создан файл `/var/www/temis/.env.production` для frontend
- [ ] Указан правильный порт (`PORT=3001`)
- [ ] Указан правильный API URL
- [ ] Создан файл `/var/www/temis/backend/.env.production` для backend
- [ ] Настроены параметры подключения к БД
- [ ] Настроены секретные ключи (SECRET_KEY и т.д.)

### Тестирование
- [ ] Este Nómada работает на `https://estenomada.es`
- [ ] Temis работает на `https://temis.es`
- [ ] Оба сайта работают одновременно без конфликтов
- [ ] Проверены логи обоих сервисов
- [ ] Проверены логи Nginx
- [ ] Проверен мониторинг ресурсов (память, CPU, диск)

---

**Готово!** Теперь у тебя два сайта работают на одном сервере без конфликтов. 🎉
