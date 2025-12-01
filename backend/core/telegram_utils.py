"""
Утилиты для работы с админским Telegram ботом.
"""
import logging
import requests
from typing import List, Optional
from django.conf import settings
from core.models import TelegramAdminBotSettings, TelegramAdmin

logger = logging.getLogger(__name__)


def send_telegram_message(chat_id: int, message: str, parse_mode: str = 'HTML') -> bool:
    """
    Отправить сообщение в Telegram.
    
    Args:
        chat_id: ID чата получателя
        message: Текст сообщения
        parse_mode: Режим парсинга (HTML или Markdown)
    
    Returns:
        True если сообщение отправлено успешно, False в противном случае
    """
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.bot_token:
        logger.debug("Telegram bot is disabled or token is not set")
        return False
    
    try:
        url = f"https://api.telegram.org/bot{bot_settings.bot_token}/sendMessage"
        payload = {
            'chat_id': chat_id,
            'text': message,
            'parse_mode': parse_mode,
        }
        
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        
        logger.info(f"Telegram message sent to chat_id {chat_id}")
        return True
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Error sending Telegram message to {chat_id}: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error sending Telegram message: {str(e)}")
        return False


def send_notification_to_authorized_admins(message: str) -> int:
    """
    Отправить уведомление всем авторизованным админам.
    
    Args:
        message: Текст сообщения
    
    Returns:
        Количество успешно отправленных сообщений
    """
    authorized_admins = TelegramAdmin.objects.filter(authorized=True)
    sent_count = 0
    
    for admin in authorized_admins:
        if send_telegram_message(admin.telegram_chat_id, message):
            sent_count += 1
    
    logger.info(f"Sent notifications to {sent_count}/{authorized_admins.count()} authorized admins")
    return sent_count


def notify_new_order(order) -> None:
    """Уведомить о новом заказе."""
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.notify_new_order:
        return
    
    # Формируем сообщение о заказе
    items_text = "\n".join([
        f"  • {item.menu_item.name} × {item.quantity} = {item.subtotal:.2f}€"
        for item in order.order_items.all()
    ])
    
    message = f"""
🆕 <b>Новый заказ #{order.id}</b>

👤 <b>Клиент:</b> {order.name or 'Не указано'}
📧 <b>Email:</b> {order.email or 'Не указано'}
📱 <b>Телефон:</b> {order.phone or 'Не указано'}

📍 <b>Адрес:</b> {order.postal_code or ''} {order.address or 'Не указано'}

🛒 <b>Блюда:</b>
{items_text}

💰 <b>Итого:</b> {order.get_total():.2f}€
🚚 <b>Доставка:</b> {order.delivery_cost:.2f}€

📝 <b>Комментарий:</b> {order.comment or 'Нет комментария'}

⏰ <b>Дата:</b> {order.created_at.strftime('%d.%m.%Y %H:%M')}
"""
    
    send_notification_to_authorized_admins(message.strip())


def notify_order_status_change(order, old_status: str, new_status: str) -> None:
    """Уведомить об изменении статуса заказа."""
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.notify_order_status_change:
        return
    
    status_emoji = {
        'pending': '⏳',
        'processing': '🔄',
        'completed': '✅',
        'cancelled': '❌',
    }
    
    emoji = status_emoji.get(new_status, '📋')
    
    message = f"""
{emoji} <b>Изменение статуса заказа #{order.id}</b>

👤 <b>Клиент:</b> {order.name or 'Не указано'}

📊 <b>Статус:</b> {old_status} → <b>{new_status}</b>

💰 <b>Сумма:</b> {order.get_total():.2f}€

⏰ <b>Время:</b> {order.updated_at.strftime('%d.%m.%Y %H:%M')}
"""
    
    send_notification_to_authorized_admins(message.strip())


def notify_new_customer(customer) -> None:
    """Уведомить о новом зарегистрированном пользователе."""
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.notify_new_customer:
        return
    
    message = f"""
👤 <b>Новый пользователь</b>

📧 <b>Email:</b> {customer.get_email_display()}
📱 <b>Телефон:</b> {customer.get_phone_display()}
👤 <b>Имя:</b> {customer.name or 'Не указано'}

{'✅ Зарегистрирован' if customer.is_registered else '❌ Не зарегистрирован'}

⏰ <b>Дата:</b> {customer.created_at.strftime('%d.%m.%Y %H:%M')}
"""
    
    send_notification_to_authorized_admins(message.strip())


def notify_review(review) -> None:
    """Уведомить об отзыве."""
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.notify_review:
        return
    
    stars = '⭐' * review.rating
    
    message = f"""
⭐ <b>Новый отзыв на заказ #{review.order.id}</b>

{stars} <b>Оценка:</b> {review.rating}/5

💬 <b>Комментарий:</b>
{review.comment or 'Без комментария'}

👤 <b>Клиент:</b> {review.order.name or 'Не указано'}

⏰ <b>Дата:</b> {review.created_at.strftime('%d.%m.%Y %H:%M')}
"""
    
    send_notification_to_authorized_admins(message.strip())

