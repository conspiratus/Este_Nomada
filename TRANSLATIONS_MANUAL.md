# Как добавить переводы вручную в админке Django

## Параметры для создания перевода

При создании нового перевода в админке Django (`/admin/core/translation/add/`) нужно заполнить следующие поля:

### 1. **Локаль (locale)**
Выберите язык:
- `ru` - Русский
- `es` - Español (Испанский)
- `en` - English (Английский)

### 2. **Пространство имён (namespace)**
Это категория перевода. Для переводов страницы заказа используйте:
- `order` - для всех переводов страницы заказа

### 3. **Ключ (key)**
Это идентификатор перевода. Для "Данные для заказа" используйте:
- `orderData` - заголовок формы заказа

Другие ключи для страницы заказа:
- `email` - метка поля Email
- `emailPlaceholder` - placeholder для поля Email

### 4. **Значение (value)**
Текст перевода на выбранном языке:
- **ru**: `Данные для заказа`
- **es**: `Datos del Pedido`
- **en**: `Order Information`

## Примеры переводов для страницы заказа

### orderData (Данные для заказа)
1. **ru**:
   - Локаль: `ru`
   - Пространство имён: `order`
   - Ключ: `orderData`
   - Значение: `Данные для заказа`

2. **es**:
   - Локаль: `es`
   - Пространство имён: `order`
   - Ключ: `orderData`
   - Значение: `Datos del Pedido`

3. **en**:
   - Локаль: `en`
   - Пространство имён: `order`
   - Ключ: `orderData`
   - Значение: `Order Information`

### email (Email)
1. **ru**:
   - Локаль: `ru`
   - Пространство имён: `order`
   - Ключ: `email`
   - Значение: `Email`

2. **es**:
   - Локаль: `es`
   - Пространство имён: `order`
   - Ключ: `email`
   - Значение: `Email`

3. **en**:
   - Локаль: `en`
   - Пространство имён: `order`
   - Ключ: `email`
   - Значение: `Email`

### emailPlaceholder (Placeholder для Email)
1. **ru**:
   - Локаль: `ru`
   - Пространство имён: `order`
   - Ключ: `emailPlaceholder`
   - Значение: `your@email.com`

2. **es**:
   - Локаль: `es`
   - Пространство имён: `order`
   - Ключ: `emailPlaceholder`
   - Значение: `your@email.com`

3. **en**:
   - Локаль: `en`
   - Пространство имён: `order`
   - Ключ: `emailPlaceholder`
   - Значение: `your@email.com`

## Как найти нужный ключ перевода

1. Откройте файл `messages/ru.json` (или `es.json`, `en.json`)
2. Найдите нужный раздел (например, `"order"`)
3. Найдите ключ (например, `"orderData"`)
4. Используйте этот ключ при создании перевода в админке

## Автоматическая загрузка переводов

Для автоматической загрузки всех переводов из JSON файлов используйте скрипт:

```bash
cd /var/www/estenomada/backend
source venv/bin/activate
python3 manage.py shell < scripts/add_order_translations.py
```

Или выполните код напрямую через `python manage.py shell`:

```python
from core.models import Translation

# Добавить перевод orderData
Translation.objects.get_or_create(
    locale='ru',
    namespace='order',
    key='orderData',
    defaults={'value': 'Данные для заказа'}
)
```

