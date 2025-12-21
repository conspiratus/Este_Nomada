# 📋 Резюме настройки сервера для проекта Temis

## 🎯 Что было настроено на сервере

На сервере `85.190.102.101` настроена инфраструктура для второго сайта **Temis** (`temis.ooo`), который будет работать параллельно с существующим сайтом Este Nómada (`estenomada.es`).

---

## ✅ Выполненные настройки

### 1. **Nginx конфигурация**

**Файл:** `/etc/nginx/sites-available/temis`  
**Символическая ссылка:** `/etc/nginx/sites-enabled/temis`

**Что настроено:**
- ✅ HTTP → HTTPS редирект (порт 80 → 443)
- ✅ HTTPS конфигурация с SSL сертификатом
- ✅ Проксирование на порт **3001** для Next.js frontend
- ✅ Проксирование на порт **8001** для Django backend API (опционально)
- ✅ Настройка кеширования для статических файлов Next.js
- ✅ Security headers (X-Frame-Options, X-Content-Type-Options, и т.д.)
- ✅ Отдельные логи: `/var/log/nginx/temis_access.log` и `/var/log/nginx/temis_error.log`

**Важно:** Конфигурация активна и работает. Nginx перезагружен.

---

### 2. **SSL сертификат (Let's Encrypt)**

**Домен:** `temis.ooo`  
**Сертификат получен:** ✅ Да  
**Путь к сертификату:** `/etc/letsencrypt/live/temis.ooo/fullchain.pem`  
**Приватный ключ:** `/etc/letsencrypt/live/temis.ooo/privkey.pem`  
**Срок действия:** До 21 марта 2026 (89 дней)  
**Автообновление:** Настроено через certbot.timer

**Статус:** HTTPS работает, сайт доступен по `https://temis.ooo`

**Примечание:** DNS для `www.temis.ooo` не настроен, поэтому сертификат получен только для `temis.ooo`. Если понадобится добавить `www`, нужно:
1. Настроить DNS запись для `www.temis.ooo`
2. Расширить сертификат: `sudo certbot --nginx -d temis.ooo -d www.temis.ooo --expand`

---

### 3. **Порты**

**Выделенные порты для Temis:**
- **3001** - для Next.js frontend (свободен, готов к использованию)
- **8001** - для Django backend API (свободен, готов к использованию)

**Текущие порты Este Nómada (не трогать!):**
- **3000** - Este Nómada frontend
- **8000** - Este Nómada backend

**Статус:** Порты свободны и готовы к использованию.

---

## 📝 Что нужно сделать команде Temis

### Шаг 1: Создать директорию проекта

```bash
ssh administrator@85.190.102.101
sudo mkdir -p /var/www/temis
sudo chown -R www-data:www-data /var/www/temis
```

### Шаг 2: Настроить systemd сервисы

Создать два systemd сервиса:

#### `/etc/systemd/system/temis-frontend.service`
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

#### `/etc/systemd/system/temis-backend.service`
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

**Важно:** Замени `temis.wsgi:application` на правильное имя Django проекта!

**Активация сервисов:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable temis-frontend
sudo systemctl enable temis-backend
# Не запускай пока, так как файлов еще нет
```

### Шаг 3: Настроить переменные окружения

#### `/var/www/temis/.env.production` (Frontend)
```env
NODE_ENV=production
PORT=3001
HOSTNAME=0.0.0.0
NEXT_PUBLIC_API_URL=https://temis.ooo/api
# или если используешь отдельный backend:
# NEXT_PUBLIC_API_URL=https://temis.ooo/backend-api
```

#### `/var/www/temis/backend/.env.production` (Backend)
```env
SECRET_KEY=твой-секретный-ключ
DEBUG=False
ALLOWED_HOSTS=temis.ooo,localhost,127.0.0.1

# Database
DB_NAME=temis_db
DB_USER=temis_user
DB_PASSWORD=твой-пароль-бд
DB_HOST=localhost
DB_PORT=3306

# И другие настройки Django
```

### Шаг 4: Настроить базу данных

```bash
sudo mysql -u root -p

# В MySQL:
CREATE DATABASE temis_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'temis_user'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON temis_db.* TO 'temis_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Шаг 5: Настроить GitHub Actions

В репозитории проекта Temis нужно:

1. **Создать `.github/workflows/` директорию**

2. **Создать `ci.yml`** (аналогично Este Nómada, но с правильным именем Django проекта)

3. **Создать `deploy.yml`** с настройками:
   - `DEPLOY_DIR="/var/www/temis"`
   - `PORT=3001` для frontend
   - `PORT=8001` для backend
   - Имена сервисов: `temis-frontend`, `temis-backend`

4. **Настроить GitHub Secrets:**
   - `PROD_SERVER_HOST` = `85.190.102.101`
   - `PROD_SERVER_USER` = `administrator`
   - `PROD_SERVER_PASSWORD` = `Jovi4AndMay2020!`

**Полная инструкция:** См. файл `TEMIS_DEPLOY_SETUP.md` в репозитории Este Nómada.

---

## 🔍 Проверка текущего состояния

### Проверить Nginx конфигурацию:
```bash
sudo nginx -t
sudo systemctl status nginx
```

### Проверить SSL сертификат:
```bash
sudo certbot certificates | grep temis
curl -I https://temis.ooo
```

### Проверить порты:
```bash
sudo ss -tlnp | grep -E ':(3001|8001)'
```

### Проверить логи Nginx:
```bash
sudo tail -f /var/log/nginx/temis_access.log
sudo tail -f /var/log/nginx/temis_error.log
```

---

## ⚠️ Важные замечания

1. **Не трогать конфигурацию Este Nómada!**
   - Este Nómada работает на портах 3000 и 8000
   - Конфигурация в `/etc/nginx/sites-available/estenomada`
   - Директория `/var/www/estenomada`

2. **Использовать правильные порты:**
   - Temis frontend: **3001** (не 3000!)
   - Temis backend: **8001** (не 8000!)

3. **Права доступа:**
   - Все файлы должны принадлежать `www-data:www-data`
   - Директории: `755`, файлы: `644`

4. **Автообновление SSL:**
   - Certbot автоматически обновит сертификат за 30 дней до истечения
   - Проверить: `sudo systemctl status certbot.timer`

5. **Логи:**
   - Nginx логи: `/var/log/nginx/temis_*.log`
   - Systemd логи: `sudo journalctl -u temis-frontend` и `sudo journalctl -u temis-backend`

---

## 📞 Контакты и доступ

**Сервер:** `85.190.102.101`  
**Пользователь:** `administrator`  
**Пароль:** `Jovi4AndMay2020!` (используется для GitHub Actions)

**SSH подключение:**
```bash
ssh administrator@85.190.102.101
```

---

## ✅ Чеклист для команды Temis

- [ ] Создана директория `/var/www/temis`
- [ ] Созданы systemd сервисы (`temis-frontend`, `temis-backend`)
- [ ] Настроены переменные окружения (`.env.production`)
- [ ] Создана база данных `temis_db`
- [ ] Настроен GitHub Actions workflow
- [ ] Настроены GitHub Secrets
- [ ] Протестирован деплой
- [ ] Проверена работа сайта на `https://temis.ooo`

---

## 📚 Дополнительная документация

Полная инструкция по настройке находится в файле:
- `TEMIS_DEPLOY_SETUP.md` (в репозитории Este Nómada)

Там описаны все шаги подробно, включая:
- Настройку systemd сервисов
- Настройку Nginx (уже сделано)
- Настройку SSL (уже сделано)
- Настройку GitHub Actions
- Решение проблем

---

**Статус:** ✅ Инфраструктура готова. Можно начинать деплой проекта Temis!
