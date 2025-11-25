# 🚀 Быстрый старт - Este Nómada

## Шаг 1: Backend (Django)

```bash
cd backend

# Создай виртуальное окружение
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# или venv\Scripts\activate  # Windows

# Установи зависимости
pip install -r requirements.txt

# Настрой переменные окружения
cp .env.example .env
# Открой .env и заполни:
# - SECRET_KEY (сгенерируй: python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
# - DB_NAME, DB_USER, DB_PASSWORD, DB_HOST
# - CORS_ALLOWED_ORIGINS=http://localhost:3000

# Инициализируй БД
python scripts/init_db.py

# Создай администратора
python scripts/create_admin.py --username admin --password admin123

# Запусти сервер
python manage.py runserver
```

Backend будет доступен на `http://localhost:8000`

## Шаг 2: Frontend (Next.js)

```bash
# В корне проекта создай .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000/api

# Установи зависимости (если еще не установлены)
npm install

# Запусти dev сервер
npm run dev
```

Frontend будет доступен на `http://localhost:3000`

## Шаг 3: Celery (опционально, для интеграций)

```bash
cd backend
source venv/bin/activate

# Убедись, что Redis запущен
# Linux: sudo systemctl start redis
# Mac: brew services start redis

# Запусти Celery worker
celery -A este_nomada worker --loglevel=info
```

## Проверка

1. **Django Admin**: `http://localhost:8000/admin/`
   - Войди с: `admin` / `admin123`

2. **Frontend**: `http://localhost:3000`
   - Должен работать и загружать данные из Django API

3. **API**: `http://localhost:8000/api/stories/`
   - Должен вернуть список историй (JSON)

## Что дальше?

1. Настрой интеграции в Django Admin:
   - Telegram: `/admin/core/settings/`
   - Добавь токены в `.env`

2. Проверь работу админки на фронтенде:
   - `http://localhost:3000/admin`
   - Войди с теми же данными

3. Для production смотри `DEPLOY.md`

## Проблемы?

### Backend не запускается
- Проверь `.env` файл
- Убедись, что MySQL доступна
- Проверь логи: `backend/logs/django.log`

### Frontend не подключается
- Проверь `NEXT_PUBLIC_API_URL` в `.env.local`
- Убедись, что backend запущен на порту 8000
- Проверь CORS в `backend/este_nomada/settings.py`

### Ошибки БД
- Убедись, что БД создана
- Проверь права доступа пользователя БД
- Выполни миграции: `python manage.py migrate`

---

**Готово! Проект работает на новом стеке.** 🎉




