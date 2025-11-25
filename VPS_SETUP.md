# Развертывание Este Nómada на VPS

## Требования

- Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- Root доступ или пользователь с sudo правами
- Минимум 1GB RAM, 10GB диска

## Шаг 1: Подключение к VPS

```bash
ssh root@your-vps-ip
# или
ssh your-user@your-vps-ip
```

## Шаг 2: Обновление системы

```bash
# Ubuntu/Debian
apt update && apt upgrade -y

# CentOS/RHEL
yum update -y
```

## Шаг 3: Установка Node.js

### Вариант A: Через NodeSource (рекомендуется)

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Проверка
node --version
npm --version
```

### Вариант B: Через NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

## Шаг 4: Установка MySQL

```bash
# Ubuntu/Debian
apt install -y mysql-server
mysql_secure_installation

# CentOS/RHEL
yum install -y mysql-server
systemctl start mysqld
systemctl enable mysqld
mysql_secure_installation
```

### Создание базы данных

```bash
mysql -u root -p
```

```sql
CREATE DATABASE estenomada CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'estenomada'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON estenomada.* TO 'estenomada'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## Шаг 5: Установка Nginx

```bash
# Ubuntu/Debian
apt install -y nginx

# CentOS/RHEL
yum install -y nginx
systemctl start nginx
systemctl enable nginx
```

## Шаг 6: Создание пользователя для приложения

```bash
adduser estenomada
usermod -aG sudo estenomada
su - estenomada
```

## Шаг 7: Клонирование/загрузка проекта

```bash
cd /home/estenomada
# Если есть git репозиторий:
# git clone https://github.com/your-repo/este-nomada.git
# Или загрузите файлы через SCP/SFTP
```

## Шаг 8: Установка зависимостей

```bash
cd este-nomada
npm install --production
npm run build
```

## Шаг 9: Настройка переменных окружения

```bash
nano .env.production
```

```env
DB_HOST=localhost
DB_USER=estenomada
DB_PASSWORD=your_secure_password
DB_NAME=estenomada
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
NODE_ENV=production
NEXT_PUBLIC_BASE_URL=https://estenomada.es
PORT=3000
```

## Шаг 10: Инициализация базы данных

```bash
npm run init-db
npm run create-admin
```

## Шаг 11: Настройка systemd service

```bash
sudo nano /etc/systemd/system/estenomada.service
```

```ini
[Unit]
Description=Este Nomada Next.js App
After=network.target

[Service]
Type=simple
User=estenomada
WorkingDirectory=/home/estenomada/este-nomada
Environment=NODE_ENV=production
EnvironmentFile=/home/estenomada/este-nomada/.env.production
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable estenomada
sudo systemctl start estenomada
sudo systemctl status estenomada
```

## Шаг 12: Настройка Nginx

```bash
sudo nano /etc/nginx/sites-available/estenomada
```

```nginx
server {
    listen 80;
    server_name estenomada.es www.estenomada.es;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/estenomada /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Шаг 13: Настройка SSL (Let's Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d estenomada.es -d www.estenomada.es
```

## Шаг 14: Настройка файрвола

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Полезные команды

```bash
# Логи приложения
sudo journalctl -u estenomada -f

# Перезапуск приложения
sudo systemctl restart estenomada

# Логи Nginx
sudo tail -f /var/log/nginx/error.log

# Проверка статуса
sudo systemctl status estenomada
sudo systemctl status nginx
sudo systemctl status mysql
```



