# Generated manually on 2025-01-XX

from django.db import migrations


def add_review_translations(apps, schema_editor):
    """Добавляем недостающие переводы для функционала отзывов на три языка (ru, es, en)."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Переводы для добавления
    translations = [
        # Русский (ru)
        ('ru', 'account', 'review', 'Отзыв'),
        ('ru', 'account', 'leaveReview', 'Оставить отзыв'),
        ('ru', 'account', 'viewReview', 'Просмотр отзыва'),
        ('ru', 'account', 'rating', 'Оценка'),
        ('ru', 'account', 'reviewPlaceholder', 'Оставьте ваш отзыв о заказе...'),
        ('ru', 'account', 'submitReview', 'Отправить отзыв'),
        ('ru', 'account', 'submitting', 'Отправка...'),
        ('ru', 'account', 'cancel', 'Отмена'),
        ('ru', 'account', 'pickup', 'Самовывоз'),
        ('ru', 'account', 'status.completed', 'Завершен'),
        ('ru', 'account', 'status.pending', 'Ожидает обработки'),
        ('ru', 'account', 'status.processing', 'Обрабатывается'),
        
        # Испанский (es)
        ('es', 'account', 'review', 'Reseña'),
        ('es', 'account', 'leaveReview', 'Dejar Reseña'),
        ('es', 'account', 'viewReview', 'Ver Reseña'),
        ('es', 'account', 'rating', 'Calificación'),
        ('es', 'account', 'reviewPlaceholder', 'Deja tu reseña sobre el pedido...'),
        ('es', 'account', 'submitReview', 'Enviar Reseña'),
        ('es', 'account', 'submitting', 'Enviando...'),
        ('es', 'account', 'cancel', 'Cancelar'),
        ('es', 'account', 'pickup', 'Recoger'),
        ('es', 'account', 'status.completed', 'Completado'),
        ('es', 'account', 'status.pending', 'Pendiente'),
        ('es', 'account', 'status.processing', 'En Proceso'),
        
        # Английский (en)
        ('en', 'account', 'review', 'Review'),
        ('en', 'account', 'leaveReview', 'Leave Review'),
        ('en', 'account', 'viewReview', 'View Review'),
        ('en', 'account', 'rating', 'Rating'),
        ('en', 'account', 'reviewPlaceholder', 'Leave your review about the order...'),
        ('en', 'account', 'submitReview', 'Submit Review'),
        ('en', 'account', 'submitting', 'Submitting...'),
        ('en', 'account', 'cancel', 'Cancel'),
        ('en', 'account', 'pickup', 'Pickup'),
        ('en', 'account', 'status.completed', 'Completed'),
        ('en', 'account', 'status.pending', 'Pending'),
        ('en', 'account', 'status.processing', 'Processing'),
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
    
    print(f'[Migration] Created/updated {created_count} review translations')


def reverse_migration(apps, schema_editor):
    """Откат миграции - удаляем созданные переводы."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Ключи для удаления
    keys_to_remove = [
        'review', 'leaveReview', 'viewReview', 'rating', 'reviewPlaceholder',
        'submitReview', 'submitting', 'cancel', 'pickup',
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


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0036_add_order_review'),
    ]

    operations = [
        migrations.RunPython(add_review_translations, reverse_migration),
    ]

