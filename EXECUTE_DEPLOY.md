# 🚀 Выполните деплой сейчас

## Проблема с DNS

Хост `ssh.czjey8yl0.service.one` не разрешается через DNS с моего окружения. Это может быть внутренний хост one.com.

## Решение: Выполните команду на вашем компьютере

### Вариант 1: Одна команда (скопируйте и выполните)

```bash
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one "cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c && git fetch origin && git checkout feature/personal-cabinet-cart 2>/dev/null || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart && git pull origin feature/personal-cabinet-cart && chmod +x scripts/deploy_all_to_prod.sh && ./scripts/deploy_all_to_prod.sh"
```

Введите пароль: `Drozdofil12345!`

### Вариант 2: Используйте скрипт RUN_DEPLOY_NOW.sh

```bash
cd /Users/conspiratus/Projects/Este_Nomada
bash RUN_DEPLOY_NOW.sh
```

Скрипт автоматически введет пароль.

### Вариант 3: Пошагово (если команда не работает)

```bash
# 1. Подключитесь к серверу
ssh -p 22 czjey8yl0_ssh@ssh.czjey8yl0.service.one
# Пароль: Drozdofil12345!

# 2. Перейдите в проект
cd /customers/d/9/4/czjey8yl0/webroots/17a5d75c

# 3. Получите изменения
git fetch origin

# 4. Переключитесь на новый бранч
git checkout feature/personal-cabinet-cart || git checkout -b feature/personal-cabinet-cart origin/feature/personal-cabinet-cart

# 5. Обновите код
git pull origin feature/personal-cabinet-cart

# 6. Запустите деплой
chmod +x scripts/deploy_all_to_prod.sh
./scripts/deploy_all_to_prod.sh
```

## Что будет сделано автоматически:

✅ Переключение на бранч `feature/personal-cabinet-cart`  
✅ Обновление кода из GitHub  
✅ Установка зависимостей (geopy, markdown)  
✅ Применение миграций  
✅ Настройка email (info@nomadadeleste.com)  
✅ Генерация ENCRYPTION_KEY  
✅ Создание настроек доставки  
✅ Сбор статических файлов  
✅ Перезапуск сервисов  
✅ Отправка тестового письма  

## После выполнения:

1. Проверьте почту `info@nomadadeleste.com` - должно прийти письмо
2. Зайдите в админку: `/admin/`
3. Настройте доставку: `/admin/core/deliverysettings/`
4. Проверьте страницу заказов: `/ru/order`

## Если хост не разрешается:

Попробуйте использовать IP адрес вместо имени хоста. Найдите IP в панели one.com или используйте:

```bash
# Попробуйте найти IP через ping или в панели one.com
ping ssh.czjey8yl0.service.one

# Или используйте IP напрямую (если знаете)
ssh -p 22 czjey8yl0_ssh@<IP_АДРЕС>
```

