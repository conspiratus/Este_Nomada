#!/usr/bin/env python3
"""
Простой скрипт для добавления переводов orderData, email, emailPlaceholder
Запуск: python manage.py shell < backend/scripts/add_order_translations.py
"""
from core.models import Translation

# Переводы для добавления
translations = [
    # orderData
    {'locale': 'ru', 'namespace': 'order', 'key': 'orderData', 'value': 'Данные для заказа'},
    {'locale': 'es', 'namespace': 'order', 'key': 'orderData', 'value': 'Datos del Pedido'},
    {'locale': 'en', 'namespace': 'order', 'key': 'orderData', 'value': 'Order Information'},
    
    # email
    {'locale': 'ru', 'namespace': 'order', 'key': 'email', 'value': 'Email'},
    {'locale': 'es', 'namespace': 'order', 'key': 'email', 'value': 'Email'},
    {'locale': 'en', 'namespace': 'order', 'key': 'email', 'value': 'Email'},
    
    # emailPlaceholder
    {'locale': 'ru', 'namespace': 'order', 'key': 'emailPlaceholder', 'value': 'your@email.com'},
    {'locale': 'es', 'namespace': 'order', 'key': 'emailPlaceholder', 'value': 'your@email.com'},
    {'locale': 'en', 'namespace': 'order', 'key': 'emailPlaceholder', 'value': 'your@email.com'},
]

created = 0
updated = 0

for trans_data in translations:
    trans, was_created = Translation.objects.get_or_create(
        locale=trans_data['locale'],
        namespace=trans_data['namespace'],
        key=trans_data['key'],
        defaults={'value': trans_data['value']}
    )
    if was_created:
        created += 1
        print(f"✅ Создан: {trans_data['locale']}/{trans_data['namespace']}.{trans_data['key']}")
    elif trans.value != trans_data['value']:
        trans.value = trans_data['value']
        trans.save()
        updated += 1
        print(f"🔄 Обновлен: {trans_data['locale']}/{trans_data['namespace']}.{trans_data['key']}")

print(f"\n📊 Итого: создано {created}, обновлено {updated}")

