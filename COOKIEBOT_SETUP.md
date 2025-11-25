# Настройка Cookiebot для новых доменов

## Проблема
Cookiebot показывает ошибку: "The domain NOMADADELESTE.COM is not authorized to show the cookie banner for domain group ID fb8cae82-2ca6-40a3-b51c-29c68530a64a"

## Решение

Есть два варианта:

### Вариант 1: Добавить новые домены в существующую группу (рекомендуется)

1. Зайди в [Cookiebot Manager](https://manage.cookiebot.com/)
2. Выбери группу доменов с ID `fb8cae82-2ca6-40a3-b51c-29c68530a64a`
3. Перейди в раздел "Domains"
4. Добавь новые домены:
   - `nomadadeleste.es`
   - `www.nomadadeleste.es`
   - `nomadadeleste.com`
   - `www.nomadadeleste.com`
5. Сохрани изменения

После этого все домены будут использовать один и тот же Cookiebot ID, и код уже настроен для этого.

### Вариант 2: Создать отдельные группы для каждого домена

1. Зайди в [Cookiebot Manager](https://manage.cookiebot.com/)
2. Создай новую группу доменов для `nomadadeleste.es` и `nomadadeleste.com`
3. Скопируй новый Cookiebot ID (будет выглядеть как `xxxx-xxxx-xxxx-xxxx-xxxx`)
4. Обнови файл `components/CookiebotLoader.tsx`:
   - Замени `'fb8cae82-2ca6-40a3-b51c-29c68530a64a'` на новый ID в строках для `nomadadeleste.es` и `nomadadeleste.com`
5. Задеплой изменения

## Текущая конфигурация

В файле `components/CookiebotLoader.tsx` настроен маппинг доменов на Cookiebot ID:

```typescript
const domainToCookiebotId: Record<string, string> = {
  'estenomada.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a',
  'www.estenomada.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a',
  'nomadadeleste.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID
  'www.nomadadeleste.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID
  'nomadadeleste.com': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID
  'www.nomadadeleste.com': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID
};
```

Если используешь Вариант 1 (добавление доменов в существующую группу), ничего менять не нужно - код уже настроен правильно.

Если используешь Вариант 2 (отдельные группы), замени TODO комментарии на реальные Cookiebot ID после создания групп.


