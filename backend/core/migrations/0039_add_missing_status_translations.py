# Generated manually on 2025-11-29

from django.db import migrations


def add_status_translations(apps, schema_editor):
    """Добавляем недостающие переводы для статусов заказов и ошибок склада."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Переводы для добавления
    translations = [
        # Русский (ru)
        ('ru', 'account', 'status.completed', 'Завершен'),
        ('ru', 'account', 'status.pending', 'Ожидает обработки'),
        ('ru', 'account', 'status.processing', 'Обрабатывается'),
        ('ru', 'order', 'insufficientStock', 'Недостаточно остатка'),
        
        # Испанский (es)
        ('es', 'account', 'status.completed', 'Completado'),
        ('es', 'account', 'status.pending', 'Pendiente'),
        ('es', 'account', 'status.processing', 'En Proceso'),
        ('es', 'order', 'insufficientStock', 'Stock insuficiente'),
        
        # Английский (en)
        ('en', 'account', 'status.completed', 'Completed'),
        ('en', 'account', 'status.pending', 'Pending'),
        ('en', 'account', 'status.processing', 'Processing'),
        ('en', 'order', 'insufficientStock', 'Insufficient stock'),
    ]
    
    created_count = 0
    for locale, namespace, key, value in translations:
        # Используем get_or_create, чтобы не создавать дубликаты
        translation, created = Translation.objects.using(db_alias).get_or_create(
            locale=locale,
            namespace=namespace,
            key=key,
            defaults={'value': value}
        )
        if created:
            created_count += 1
        else:
            # Если перевод уже существует, обновляем его значение
            translation.value = value
            translation.save(using=db_alias)
    
    print(f'[Migration] Created/updated {created_count} status translations')


def reverse_migration(apps, schema_editor):
    """Откат миграции - удаляем созданные переводы."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Ключи для удаления
    keys_to_remove = [
        'status.completed', 'status.pending', 'status.processing'
    ]
    
    locales = ['ru', 'es', 'en']
    
    for locale in locales:
        for key in keys_to_remove:
            Translation.objects.using(db_alias).filter(
                locale=locale,
                namespace='account',
                key=key
            ).delete()
        
        # Удаляем также order.insufficientStock
        Translation.objects.using(db_alias).filter(
            locale=locale,
            namespace='order',
            key='insufficientStock'
        ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0038_add_stock_and_ingredients'),
    ]

    operations = [
        migrations.RunPython(add_status_translations, reverse_migration),
    ]

