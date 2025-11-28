#!/usr/bin/env python3
"""
Скрипт для исправления переводов orderData, email, emailPlaceholder
"""
from core.models import Translation

# Обновляем orderData
translations_orderData = [
    ("ru", "Данные для заказа"),
    ("es", "Datos del Pedido"),
    ("en", "Order Information"),
]

for locale, value in translations_orderData:
    trans, created = Translation.objects.get_or_create(
        locale=locale,
        namespace="order",
        key="orderData",
        defaults={"value": value}
    )
    if not created and trans.value != value:
        trans.value = value
        trans.save()
        print(f"✅ Обновлен: {locale}/order.orderData = {value}")
    elif created:
        print(f"✅ Создан: {locale}/order.orderData = {value}")

# Обновляем email
for locale in ["ru", "es", "en"]:
    trans, created = Translation.objects.get_or_create(
        locale=locale,
        namespace="order",
        key="email",
        defaults={"value": "Email"}
    )
    if not created and trans.value != "Email":
        trans.value = "Email"
        trans.save()
        print(f"✅ Обновлен: {locale}/order.email = Email")
    elif created:
        print(f"✅ Создан: {locale}/order.email = Email")

# Создаем emailPlaceholder
for locale in ["ru", "es", "en"]:
    trans, created = Translation.objects.get_or_create(
        locale=locale,
        namespace="order",
        key="emailPlaceholder",
        defaults={"value": "your@email.com"}
    )
    if created:
        print(f"✅ Создан: {locale}/order.emailPlaceholder = your@email.com")
    else:
        print(f"ℹ️  Уже существует: {locale}/order.emailPlaceholder = {trans.value}")

print("\n✨ Готово!")

