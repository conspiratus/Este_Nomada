"""
Django signals для автоматических уведомлений в Telegram.
"""
import logging
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from core.models import Order, Customer, OrderReview
from core.telegram_utils import (
    notify_new_order,
    notify_order_status_change,
    notify_new_customer,
    notify_review
)

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Order)
def order_created(sender, instance, created, **kwargs):
    """Обработчик создания нового заказа."""
    # НЕ отправляем уведомление здесь, так как order_items еще не созданы
    # Уведомление отправляется вручную в OrderViewSet.create после создания всех order_items
    # Это гарантирует, что все данные заказа готовы перед отправкой уведомления
    pass


# Временное хранилище для старого статуса заказа
_order_status_cache = {}


@receiver(pre_save, sender=Order)
def order_pre_save(sender, instance, **kwargs):
    """Сохраняем старый статус перед сохранением."""
    if instance.pk:
        try:
            old_order = Order.objects.get(pk=instance.pk)
            _order_status_cache[instance.pk] = old_order.status
        except Order.DoesNotExist:
            pass


@receiver(post_save, sender=Order)
def order_post_save(sender, instance, created, **kwargs):
    """Проверяем изменение статуса после сохранения."""
    if not created and instance.pk in _order_status_cache:
        old_status = _order_status_cache.pop(instance.pk)
        if old_status != instance.status:
            try:
                notify_order_status_change(instance, old_status, instance.status)
            except Exception as e:
                logger.error(f"Error notifying about order status change {instance.id}: {str(e)}")


@receiver(post_save, sender=Customer)
def customer_created(sender, instance, created, **kwargs):
    """Обработчик создания нового пользователя."""
    if created and instance.is_registered:
        try:
            notify_new_customer(instance)
        except Exception as e:
            logger.error(f"Error notifying about new customer {instance.id}: {str(e)}")


@receiver(post_save, sender=OrderReview)
def review_created(sender, instance, created, **kwargs):
    """Обработчик создания отзыва."""
    if created:
        try:
            notify_review(instance)
        except Exception as e:
            logger.error(f"Error notifying about review {instance.id}: {str(e)}")
