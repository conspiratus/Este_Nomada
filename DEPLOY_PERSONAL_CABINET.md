# Деплой Личного Кабинета и Корзины на Production

## Бранч
**feature/personal-cabinet-cart** - все изменения находятся в этом бранче.

## Важные шаги перед деплоем

### 1. Создать резервную копию базы данных
```bash
# На сервере
mysqldump -u username -p database_name > backup_before_personal_cabinet.sql
```

### 2. Настроить переменные окружения

Добавить в `.env` на сервере:
```env
# Ключ шифрования (ОБЯЗАТЕЛЬНО!)
# Сгенерировать: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
ENCRYPTION_KEY=ваш_ключ_шифрования

# Email для подтверждений (опционально)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### 3. Установить зависимости

```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
# Установятся: geopy, markdown (если еще не установлены)
```

### 4. Применить миграции

```bash
cd backend
source venv/bin/activate
python manage.py migrate
```

**Внимание:** Если возникнут проблемы с миграциями (как было локально), можно применить только новую:
```bash
python manage.py migrate core 0027
```

### 5. Настроить доставку в админке

После деплоя:
1. Зайти в админку: `/admin/`
2. Перейти в "Настройки доставки и ЛК"
3. Указать:
   - Координаты точки доставки (широта, долгота)
   - Базовую стоимость доставки
   - Стоимость за километр
   - Порог бесплатной доставки (опционально)
   - Максимальное расстояние доставки (опционально)

### 6. Перезапустить сервисы

```bash
# Backend
sudo systemctl restart estenomada-backend

# Frontend (если используется systemd)
sudo systemctl restart estenomada-frontend

# Или через PM2/supervisor
pm2 restart all
```

## Процесс деплоя

### Вариант 1: Через GitHub Actions (если настроено)

1. Создать Pull Request из `feature/personal-cabinet-cart` в `main`
2. После проверки - мерджнуть
3. GitHub Actions автоматически задеплоит

### Вариант 2: Ручной деплой

```bash
# На сервере
cd /path/to/Este_Nomada
git fetch origin
git checkout feature/personal-cabinet-cart
git pull origin feature/personal-cabinet-cart

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
sudo systemctl restart estenomada-backend

# Frontend
cd ..
npm install
npm run build
sudo systemctl restart estenomada-frontend
```

## Откат изменений (если что-то пошло не так)

```bash
# Вернуться на старый бранч
git checkout main
git pull origin main

# Или откатить миграции
cd backend
source venv/bin/activate
python manage.py migrate core 0026  # откатить до предыдущей миграции

# Восстановить БД из бэкапа
mysql -u username -p database_name < backup_before_personal_cabinet.sql
```

## Проверка после деплоя

1. ✅ Проверить, что страница заказов открывается: `https://estenomada.es/ru/order`
2. ✅ Проверить API: `https://estenomada.es/api/cart/`
3. ✅ Проверить админку: `https://estenomada.es/admin/`
4. ✅ Создать тестовый заказ
5. ✅ Проверить расчет доставки

## Важные замечания

- ⚠️ **ENCRYPTION_KEY** должен быть одинаковым на всех серверах, иначе не получится расшифровать данные
- ⚠️ После изменения ENCRYPTION_KEY все зашифрованные данные станут нечитаемыми
- ⚠️ Обязательно сделать бэкап БД перед деплоем
- ⚠️ Проверить, что все миграции применены успешно

## Ссылки

- Pull Request: https://github.com/conspiratus/Este_Nomada/pull/new/feature/personal-cabinet-cart
- Инструкция по настройке: `SETUP_PERSONAL_CABINET.md`

