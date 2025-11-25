# Инструкции по добавлению контента

## Изображения

### 1. Логотип
- Разместите логотип в `/public/logo.svg` или `/public/logo.png`
- Обновите компонент `Header.tsx` (раскомментируйте строки с Image)
- Также обновите `Hero.tsx` для использования логотипа вместо "EN"

### 2. Hero-блок
- Добавьте фоновое изображение в `/public/hero-bg.jpg`
- Раскомментируйте код в `components/sections/Hero.tsx` (строки 20-26)

### 3. О бренде
- Добавьте изображение Извозчика у казана в `/public/about-brand.jpg`
- Обновите `components/sections/AboutBrand.tsx` для использования реального изображения

### 4. Меню
- Добавьте фотографии блюд в `/public/menu/`
- Обновите `components/sections/Menu.tsx` для использования реальных изображений

### 5. Карта пути
- Добавьте карту-плов в `/public/path-map.jpg`
- Обновите `components/sections/PathMap.tsx`

### 6. Истории
- Добавьте обложки статей в `/public/stories/`
- Обновите пути в `app/stories/[slug]/page.tsx` и `components/sections/Stories.tsx`

## Тексты

### О бренде
Отредактируйте текст в `components/sections/AboutBrand.tsx` (строки 30-50)

### Истории
Добавьте новые истории в `app/stories/[slug]/page.tsx` в объект `stories`

### Меню
Обновите список блюд в `components/sections/Menu.tsx` (массив `menuItems`)

## Настройки

### Email
Обновите email в `components/Footer.tsx` (строка с `mailto:`)

### Telegram
Ссылка на Telegram уже настроена: `https://t.me/este_nomada`

## Деплой на one.com

1. Соберите проект: `npm run build`
2. Загрузите папку `.next` и `public` на сервер
3. Настройте сервер для работы с Next.js (SSR)




