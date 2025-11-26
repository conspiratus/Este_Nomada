# Руководство по миграции на Django Backend

Это руководство поможет тебе мигрировать проект с Next.js API routes на Django backend.

## Шаг 1: Подготовка

### 1.1. Создай резервную копию БД

```bash
mysqldump -u username -p database_name > backup.sql
```

### 1.2. Установи зависимости для Django

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 1.3. Настрой переменные окружения

Скопируй `backend/.env.example` в `backend/.env` и заполни:

```env
SECRET_KEY=твой-секретный-ключ
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,estenomada.es

DB_NAME=czjey8yl0_estenomada
DB_USER=czjey8yl0_estenomada
DB_PASSWORD=твой-пароль
DB_HOST=localhost
DB_PORT=3306

CORS_ALLOWED_ORIGINS=http://localhost:3000,https://estenomada.es
```

## Шаг 2: Инициализация Django

### 2.1. Создай миграции

```bash
cd backend
python manage.py makemigrations
python manage.py migrate
```

### 2.2. Инициализируй БД

```bash
python scripts/init_db.py
```

### 2.3. Создай администратора

```bash
python scripts/create_admin.py --username admin --password admin123
```

### 2.4. Мигрируй существующие данные (если есть)

```bash
python scripts/migrate_data.py
```

## Шаг 3: Настройка фронтенда

### 3.1. Обнови переменные окружения

Создай `.env.local` в корне проекта:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api
```

В продакшене:

```env
NEXT_PUBLIC_API_URL=https://api.estenomada.es/api
```

### 3.2. Обнови компоненты админки

Все компоненты админки теперь используют `lib/api.ts` вместо прямых запросов к Next.js API routes.

## Шаг 4: Запуск

### 4.1. Запусти Django сервер

```bash
cd backend
source venv/bin/activate
python manage.py runserver
```

### 4.2. Запусти Next.js фронтенд

```bash
npm run dev
```

### 4.3. Запусти Celery (для интеграций)

В отдельном терминале:

```bash
cd backend
source venv/bin/activate
celery -A este_nomada worker --loglevel=info
```

## Шаг 5: Проверка

1. Открой `http://localhost:8000/admin/` - Django Admin должен работать
2. Открой `http://localhost:3000` - фронтенд должен работать
3. Попробуй войти в админку на фронтенде - авторизация должна работать через Django API

## Шаг 6: Деплой

### 6.1. Настрой production переменные

В `backend/.env` на сервере:

```env
DEBUG=False
ALLOWED_HOSTS=api.estenomada.es
CORS_ALLOWED_ORIGINS=https://estenomada.es
```

### 6.2. Собери статические файлы

```bash
python manage.py collectstatic --noinput
```

### 6.3. Запусти через Gunicorn

```bash
gunicorn este_nomada.wsgi:application --bind 0.0.0.0:8000
```

### 6.4. Настрой Nginx

Пример конфигурации для API:

```nginx
server {
    listen 80;
    server_name api.estenomada.es;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Что изменилось

### ✅ Улучшения

1. **Безопасность**: Все запросы к БД через ORM, без прямых SQL
2. **Валидация**: Автоматическая валидация через сериализаторы
3. **Админка**: Готовая Django Admin из коробки
4. **Миграции**: Управление схемой БД через миграции Django
5. **Интеграции**: Celery для фоновых задач

### 🔄 Изменения в коде

- API endpoints теперь в Django (`/api/...`)
- Авторизация через JWT (Django REST Framework)
- Компоненты админки используют `lib/api.ts`
- Все модели в `backend/core/models.py`

### 📝 Новые файлы

- `backend/` - Django проект
- `lib/api.ts` - API клиент для фронтенда
- `MIGRATION_GUIDE.md` - это руководство

## Поддержка

Если возникли проблемы:

1. Проверь логи Django: `backend/logs/django.log`
2. Проверь логи Celery
3. Проверь переменные окружения
4. Убедись, что БД доступна




