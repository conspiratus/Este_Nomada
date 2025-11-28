# 🚀 Деплой из бранча feature/personal-cabinet-cart на Production

## Важно!

На проде сейчас старая версия (main/master). Новая версия находится в бранче `feature/personal-cabinet-cart` в GitHub.

## Автоматический деплой (1 команда):

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one "cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart && chmod +x scripts/deploy_all_to_prod.sh && ./scripts/deploy_all_to_prod.sh"
```

## Пошаговый деплой:

```bash
# 1. Подключитесь к серверу
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one

# 2. Перейдите в проект
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c

# 3. Получите последние изменения из GitHub
git fetch origin

# 4. Переключитесь на бранч feature/personal-cabinet-cart
git checkout feature/personal-cabinet-cart
# Если бранч не существует локально, создастся из origin:
# git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart

# 5. Обновите код
git pull origin feature/personal-cabinet-cart

# 6. Запустите полный деплой
chmod +x scripts/deploy_all_to_prod.sh
./scripts/deploy_all_to_prod.sh
```

## Что произойдет:

1. ✅ Код переключится на бранч `feature/personal-cabinet-cart`
2. ✅ Обновятся все файлы из этого бранча
3. ✅ Установятся зависимости
4. ✅ Применятся миграции
5. ✅ Настроится email (info@nomadadeleste.com)
6. ✅ Все будет готово к работе

## После деплоя:

### Вариант 1: Оставить на бранче (для тестирования)

Оставьте как есть - код будет работать из бранча `feature/personal-cabinet-cart`.

### Вариант 2: Замержить в main (для production)

Если все работает хорошо:

```bash
# На сервере
git checkout main
git merge feature/personal-cabinet-cart
git push origin main

# Это запустит CI/CD (если настроен)
```

## Откат (если что-то пошло не так):

```bash
# Вернуться на старый бранч
git checkout main
git pull origin main

# Или конкретный коммит
git checkout <старый-коммит-hash>
```

## Проверка текущего бранча:

```bash
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c
git branch --show-current
# Должно показать: feature/personal-cabinet-cart
```

## Важно:

⚠️ **Не переключайтесь обратно на main** до тестирования!  
⚠️ **Сделайте бэкап БД** перед деплоем!  
⚠️ **Проверьте работу** перед мерджем в main!

