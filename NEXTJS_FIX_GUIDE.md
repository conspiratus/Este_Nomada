# Руководство по исправлению ошибок Next.js в Production

## Проблема

Сайт возвращает **500 Internal Server Error** с ошибками:
- `Cannot read properties of undefined (reading 'previewModeId')`
- `Cannot read properties of undefined (reading '/_error')`

Это указывает на проблему с инициализацией Next.js в production, обычно связанную с отсутствием или повреждением `prerender-manifest.json`.

## Быстрое исправление

### Вариант 1: Быстрое исправление только prerender-manifest.json

Если проблема только в отсутствующем `prerender-manifest.json`:

```bash
# На сервере в директории /var/www/estenomada
cd /var/www/estenomada
bash scripts/quick_fix_prerender.sh
```

Этот скрипт:
1. Остановит сервис
2. Создаст/исправит `prerender-manifest.json`
3. Запустит сервис обратно

### Вариант 2: Полная диагностика и исправление

Если быстрое исправление не помогло:

```bash
# 1. Сначала диагностика
cd /var/www/estenomada
bash scripts/diagnose_and_fix_nextjs.sh

# 2. Затем полное исправление
bash scripts/fix_nextjs_production.sh
```

## Ручное исправление

Если скрипты недоступны, выполните вручную:

### 1. Остановите сервис

```bash
sudo systemctl stop estenomada-frontend
```

### 2. Создайте prerender-manifest.json

```bash
cd /var/www/estenomada
cat > .next/prerender-manifest.json << 'EOF'
{
  "version": 4,
  "routes": {},
  "dynamicRoutes": {},
  "notFoundRoutes": [],
  "preview": {
    "previewModeId": "",
    "previewModeSigningKey": "",
    "previewModeEncryptionKey": ""
  }
}
EOF
```

### 3. Установите права

```bash
sudo chown www-data:www-data .next/prerender-manifest.json
chmod 644 .next/prerender-manifest.json
```

### 4. Если проблема не решена - полная пересборка

```bash
cd /var/www/estenomada

# Очистка
rm -rf .next
rm -rf node_modules/.cache

# Установка зависимостей (если нужно)
npm ci

# Сборка
export NODE_ENV=production
npm run build

# Проверка сборки
ls -la .next/prerender-manifest.json

# Запуск
sudo systemctl start estenomada-frontend
```

## Проверка результата

### Проверка статуса сервиса

```bash
sudo systemctl status estenomada-frontend
```

### Проверка логов

```bash
# Последние 50 строк
sudo journalctl -u estenomada-frontend -n 50

# В реальном времени
sudo journalctl -u estenomada-frontend -f
```

### Проверка доступности

```bash
# Локально
curl -I http://localhost:3000

# Через nginx
curl -I https://estenomada.es
```

## Обновление systemd сервиса

Если вы обновили конфигурацию systemd, примените изменения:

```bash
# Скопируйте обновленный файл
sudo cp /var/www/estenomada/systemd/estenomada-frontend.service /etc/systemd/system/

# Перезагрузите systemd
sudo systemctl daemon-reload

# Перезапустите сервис
sudo systemctl restart estenomada-frontend
```

## Частые проблемы

### 1. Файл prerender-manifest.json отсутствует после сборки

**Причина:** Проблема при сборке проекта

**Решение:** 
- Убедитесь, что `NODE_ENV=production` установлен
- Проверьте, что все зависимости установлены: `npm ci`
- Выполните полную пересборку: `rm -rf .next && npm run build`

### 2. Ошибки прав доступа

**Причина:** Неправильные права на файлы

**Решение:**
```bash
sudo chown -R www-data:www-data /var/www/estenomada/.next
sudo chmod -R 755 /var/www/estenomada/.next
```

### 3. Сервис не запускается

**Причина:** Ошибки в логах или конфигурации

**Решение:**
```bash
# Проверьте логи
sudo journalctl -u estenomada-frontend -n 100

# Проверьте переменные окружения
cat /var/www/estenomada/.env.production

# Проверьте, что Node.js доступен
which node
which npm
```

### 4. Порт 3000 уже занят

**Причина:** Другой процесс использует порт

**Решение:**
```bash
# Найти процесс
sudo lsof -i :3000

# Остановить процесс или изменить порт в .env.production
```

## Дополнительная диагностика

### Проверка структуры .next

```bash
cd /var/www/estenomada
ls -la .next/
ls -la .next/server/
```

Должны присутствовать:
- `BUILD_ID`
- `package.json` или `server.js`
- `prerender-manifest.json`
- `static/`

### Проверка переменных окружения

```bash
cd /var/www/estenomada
cat .env.production | grep -E "^(NODE_ENV|PORT|HOSTNAME|NEXT_PUBLIC)"
```

Должны быть установлены:
- `NODE_ENV=production`
- `PORT=3000`
- `HOSTNAME=0.0.0.0`
- `NEXT_PUBLIC_API_URL=...`
- `NEXT_PUBLIC_BASE_URL=...`

## Контакты и поддержка

Если проблема не решена после выполнения всех шагов, проверьте:
1. Логи systemd на наличие других ошибок
2. Логи nginx для ошибок проксирования
3. Доступность базы данных (если используется)
4. Версию Node.js (рекомендуется 18.x или выше)

