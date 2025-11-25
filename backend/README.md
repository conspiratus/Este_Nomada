# Este Nómada - Django Backend

Backend для проекта Este Nómada на Django + Django REST Framework.

## Установка

### 1. Создать виртуальное окружение

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# или
venv\Scripts\activate  # Windows
```

### 2. Установить зависимости

```bash
pip install -r requirements.txt
```

### 3. Настроить переменные окружения

Скопируй `.env.example` в `.env` и заполни:

```bash
cp .env.example .env
```

Обязательно укажи:
- `SECRET_KEY` - секретный ключ Django
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST` - данные БД
- `CORS_ALLOWED_ORIGINS` - URL фронтенда

### 4. Выполнить миграции

```bash
python manage.py makemigrations
python manage.py migrate
```

### 5. Создать администратора

```bash
python scripts/create_admin.py --username admin --password admin123
```

Или через Django:

```bash
python manage.py createsuperuser
```

### 6. Загрузить начальные данные (опционально)

```bash
python manage.py loaddata initial_data.json  # если есть
```

## Запуск

### Development сервер

```bash
python manage.py runserver
```

Сервер запустится на `http://localhost:8000`

### Celery Worker (для фоновых задач)

В отдельном терминале:

```bash
celery -A este_nomada worker --loglevel=info
```

### Celery Beat (для периодических задач)

В отдельном терминале:

```bash
celery -A este_nomada beat --loglevel=info
```

## API Endpoints

### Публичные (без авторизации)

- `GET /api/stories/` - список историй
- `GET /api/stories/{slug}/` - одна история
- `GET /api/menu/` - меню
- `GET /api/settings/public/` - публичные настройки
- `POST /api/orders/` - создать заказ
- `GET /api/instagram/feed/` - лента Instagram

### Админка (требуется авторизация)

- `POST /api/auth/login/` - вход (получить JWT токен)
- `POST /api/auth/refresh/` - обновить токен
- `GET /api/stories/` - список всех историй (включая неопубликованные)
- `POST /api/stories/` - создать историю
- `PUT /api/stories/{id}/` - обновить историю
- `DELETE /api/stories/{id}/` - удалить историю
- Аналогично для `/api/menu/` и `/api/settings/`

## Django Admin

Доступ: `http://localhost:8000/admin/`

Войди с учетными данными администратора.

## Структура проекта

```
backend/
├── este_nomada/          # Основные настройки Django
│   ├── settings.py      # Настройки
│   ├── urls.py          # Главные URL
│   └── celery.py        # Конфигурация Celery
├── core/                # Основные модели
│   ├── models.py       # Story, MenuItem, Settings, Order, etc.
│   └── admin.py        # Django Admin конфигурация
├── api/                 # API endpoints
│   ├── views.py        # ViewSets
│   ├── serializers.py  # Сериализаторы
│   ├── urls.py         # API URLs
│   └── tasks.py        # Celery задачи
├── scripts/             # Утилиты
│   └── create_admin.py # Создание администратора
└── manage.py           # Django CLI
```

## Интеграции

### Telegram

Настрой в Django Admin (`/admin/core/settings/`):
- `bot_token` - токен Telegram бота
- `channel_id` - ID канала
- `auto_sync` - включить автосинхронизацию

Запусти Celery worker для синхронизации.

### OpenAI

Настрой в `.env`:
```
OPENAI_API_KEY=your-key
```

При создании заказа автоматически обрабатывается через ChatGPT.

### Instagram

Настрой в `.env`:
```
INSTAGRAM_APP_ID=your-app-id
INSTAGRAM_APP_SECRET=your-app-secret
INSTAGRAM_ACCESS_TOKEN=your-access-token
```

Запусти Celery beat для периодической синхронизации.

## Деплой

### Production настройки

1. Установи `DEBUG=False` в `.env`
2. Настрой `ALLOWED_HOSTS`
3. Настрой `CORS_ALLOWED_ORIGINS`
4. Используй PostgreSQL вместо MySQL (рекомендуется)
5. Настрой статические файлы: `python manage.py collectstatic`
6. Используй Gunicorn: `gunicorn este_nomada.wsgi:application`

### Systemd service

Создай файл `/etc/systemd/system/estenomada.service`:

```ini
[Unit]
Description=Este Nomada Django
After=network.target

[Service]
User=www-data
WorkingDirectory=/path/to/backend
Environment="PATH=/path/to/venv/bin"
ExecStart=/path/to/venv/bin/gunicorn este_nomada.wsgi:application --bind 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## Безопасность

- ✅ Все запросы к БД через ORM (без прямых SQL)
- ✅ JWT авторизация для API
- ✅ Валидация данных через сериализаторы
- ✅ CORS настроен правильно
- ✅ Пароли хешируются Django
- ✅ CSRF защита включена



