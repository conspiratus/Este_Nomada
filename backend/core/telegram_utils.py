"""
Утилиты для работы с админским Telegram ботом.
"""
import logging
import requests
from typing import List, Optional
from django.conf import settings
from core.models import TelegramAdminBotSettings, TelegramAdmin

logger = logging.getLogger(__name__)


def send_telegram_message(chat_id: int, message: str, parse_mode: str = 'HTML', reply_markup: dict = None, check_banned: bool = True) -> bool:
    """
    Отправить сообщение в Telegram.
    
    Args:
        chat_id: ID чата получателя
        message: Текст сообщения
        parse_mode: Режим парсинга (HTML или Markdown)
        reply_markup: Inline keyboard markup (опционально)
        check_banned: Проверять ли статус бана перед отправкой
    
    Returns:
        True если сообщение отправлено успешно, False в противном случае
    """
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.bot_token:
        logger.debug("Telegram bot is disabled or token is not set")
        return False
    
    # Проверяем, не забанен ли пользователь
    if check_banned:
        try:
            admin = TelegramAdmin.objects.filter(telegram_chat_id=chat_id).first()
            if admin and admin.banned:
                logger.debug(f"User {chat_id} is banned, skipping message")
                return False
        except Exception as e:
            logger.error(f"Error checking banned status for {chat_id}: {str(e)}")
            # Продолжаем отправку, если не удалось проверить
    
    try:
        url = f"https://api.telegram.org/bot{bot_settings.bot_token}/sendMessage"
        payload = {
            'chat_id': chat_id,
            'text': message,
            'parse_mode': parse_mode,
        }
        
        if reply_markup:
            payload['reply_markup'] = reply_markup
        
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


def answer_callback_query(callback_query_id: str, text: str = None, show_alert: bool = False) -> bool:
    """
    Ответить на callback query.
    
    Args:
        callback_query_id: ID callback query
        text: Текст ответа (опционально)
        show_alert: Показать alert вместо уведомления
    
    Returns:
        True если успешно, False в противном случае
    """
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.bot_token:
        return False
    
    try:
        url = f"https://api.telegram.org/bot{bot_settings.bot_token}/answerCallbackQuery"
        payload = {
            'callback_query_id': callback_query_id,
        }
        
        if text:
            payload['text'] = text
        if show_alert:
            payload['show_alert'] = True
        
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        
        return True
        
    except Exception as e:
        logger.error(f"Error answering callback query {callback_query_id}: {str(e)}")
        return False


def edit_message_text(chat_id: int, message_id: int, text: str, parse_mode: str = 'HTML', reply_markup: dict = None) -> bool:
    """
    Редактировать текст сообщения в Telegram.
    
    Args:
        chat_id: ID чата
        message_id: ID сообщения
        text: Новый текст
        parse_mode: Режим парсинга
        reply_markup: Inline keyboard markup (опционально)
    
    Returns:
        True если успешно, False в противном случае
    """
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.bot_token:
        return False
    
    try:
        url = f"https://api.telegram.org/bot{bot_settings.bot_token}/editMessageText"
        payload = {
            'chat_id': chat_id,
            'message_id': message_id,
            'text': text,
            'parse_mode': parse_mode,
        }
        
        if reply_markup:
            payload['reply_markup'] = reply_markup
        
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        
        return True
        
    except Exception as e:
        logger.error(f"Error editing message {message_id} in chat {chat_id}: {str(e)}")
        return False


def send_notification_to_authorized_admins(message: str) -> int:
    """
    Отправить уведомление всем авторизованным админам (не забаненным).
    
    Args:
        message: Текст сообщения
    
    Returns:
        Количество успешно отправленных сообщений
    """
    authorized_admins = TelegramAdmin.objects.filter(authorized=True, banned=False)
    sent_count = 0
    
    for admin in authorized_admins:
        if send_telegram_message(admin.telegram_chat_id, message, check_banned=False):
            sent_count += 1
    
    logger.info(f"Sent notifications to {sent_count}/{authorized_admins.count()} authorized admins")
    return sent_count


def get_main_menu_keyboard() -> dict:
    """
    Создать главное меню бота.
    
    Returns:
        Словарь с inline keyboard markup
    """
    return {
        'inline_keyboard': [
            [{'text': '📋 Текущие заказы', 'callback_data': 'menu_orders_page_0'}],
            [{'text': '🍽️ Готовая продукция', 'callback_data': 'menu_stock'}],
            [{'text': '📦 Склад', 'callback_data': 'menu_warehouse'}],
        ]
    }


def get_orders_list_keyboard(page: int = 0, orders_per_page: int = 5):
    """
    Создать список заказов с пагинацией.
    
    Args:
        page: Номер страницы (начиная с 0)
        orders_per_page: Количество заказов на странице
    
    Returns:
        Tuple (keyboard, message_text)
    """
    from core.models import Order
    
    # Получаем настройки бота для фильтрации по статусам
    bot_settings = TelegramAdminBotSettings.get_settings()
    display_statuses = bot_settings.get_orders_display_statuses_list()
    
    # Получаем заказы с фильтрацией по статусам, отсортированные по дате создания (новые первые)
    all_orders = Order.objects.filter(status__in=display_statuses).select_related('customer').prefetch_related('order_items__menu_item').order_by('-created_at')
    total_orders = all_orders.count()
    
    # Вычисляем пагинацию
    start_idx = page * orders_per_page
    end_idx = start_idx + orders_per_page
    orders = list(all_orders[start_idx:end_idx])
    
    # Формируем текст сообщения
    if total_orders == 0:
        message = "📋 <b>Текущие заказы</b>\n\nЗаказов пока нет."
        keyboard = {'inline_keyboard': [[{'text': '🔙 Главное меню', 'callback_data': 'menu_main'}]]}
        return keyboard, message
    
    message = f"📋 <b>Текущие заказы</b>\n\n"
    message += f"Страница {page + 1} из {(total_orders - 1) // orders_per_page + 1}\n"
    message += f"Всего заказов: {total_orders}\n\n"
    
    # Формируем кнопки для заказов
    keyboard_buttons = []
    for order in orders:
        # Получаем имя клиента
        customer_name = order.name if order.name else (order.customer.name if order.customer else "Без имени")
        # Ограничиваем длину имени для кнопки
        if len(customer_name) > 20:
            customer_name = customer_name[:17] + "..."
        
        # Получаем общую стоимость
        total = order.get_total()
        
        # Формируем текст кнопки: #ID Имя Стоимость€
        button_text = f"#{order.id} {customer_name} {total:.2f}€"
        # Telegram ограничивает длину текста кнопки до 64 символов
        if len(button_text) > 64:
            button_text = f"#{order.id} {customer_name[:50-len(f' {total:.2f}€')]} {total:.2f}€"
        
        keyboard_buttons.append([{'text': button_text, 'callback_data': f'order_detail_{order.id}'}])
    
    # Добавляем кнопки навигации
    nav_buttons = []
    if page > 0:
        nav_buttons.append({'text': '◀️ Назад', 'callback_data': f'menu_orders_page_{page - 1}'})
    if end_idx < total_orders:
        nav_buttons.append({'text': 'Далее ▶️', 'callback_data': f'menu_orders_page_{page + 1}'})
    
    if nav_buttons:
        keyboard_buttons.append(nav_buttons)
    
    # Кнопка возврата в главное меню
    keyboard_buttons.append([{'text': '🔙 Главное меню', 'callback_data': 'menu_main'}])
    
    keyboard = {'inline_keyboard': keyboard_buttons}
    return keyboard, message


def format_order_details(order) -> str:
    """
    Форматировать детальную информацию о заказе.
    
    Args:
        order: Объект Order
    
    Returns:
        Отформатированная строка с информацией о заказе
    """
    # Получаем элементы заказа
    order_items = list(order.order_items.select_related('menu_item').all())
    
    # Формируем список блюд
    if order_items:
        items_list = []
        for item in order_items:
            try:
                item_name = item.menu_item.name if item.menu_item else f"Блюдо #{item.menu_item_id}"
                item_price = float(item.menu_item.price) if item.menu_item and item.menu_item.price else 0
                subtotal = item_price * item.quantity
                items_list.append(f"  • {item_name} × {item.quantity} = {subtotal:.2f}€")
            except Exception as e:
                logger.error(f"Error processing order item {item.id}: {str(e)}")
                items_list.append(f"  • Блюдо #{item.menu_item_id} × {item.quantity} (ошибка)")
        items_text = "\n".join(items_list)
    else:
        items_text = "  (Блюда не найдены)"
    
    # Определяем адрес доставки
    if order.is_pickup:
        address_text = "🚶 <b>Самовывоз</b>"
    elif order.postal_code or order.address:
        address_text = f"{order.postal_code or ''} {order.address or ''}".strip()
    else:
        address_text = "Не указано"
    
    # Получаем имя клиента
    customer_name = order.name if order.name else (order.customer.name if order.customer else "Не указано")
    
    # Статус заказа
    status_names = dict(order.STATUS_CHOICES)
    status_text = status_names.get(order.status, order.status)
    
    message = f"""
📦 <b>Заказ #{order.id}</b>

👤 <b>Клиент:</b> {customer_name}
📧 <b>Email:</b> {order.email or 'Не указано'}
📱 <b>Телефон:</b> {order.phone or 'Не указано'}

📍 <b>Адрес:</b> {address_text}

🛒 <b>Блюда:</b>
{items_text}

💰 <b>Итого:</b> {order.get_total():.2f}€
🚚 <b>Доставка:</b> {order.delivery_cost:.2f}€

📝 <b>Комментарий:</b> {order.comment or 'Нет комментария'}

📊 <b>Статус:</b> {status_text}

⏰ <b>Дата:</b> {order.created_at.strftime('%d.%m.%Y %H:%M')}
"""
    
    return message.strip()


def get_order_status_keyboard(order_id: int, current_status: str, include_menu_button: bool = True) -> dict:
    """
    Создать inline keyboard для изменения статуса заказа.
    
    Args:
        order_id: ID заказа
        current_status: Текущий статус заказа
        include_menu_button: Добавить кнопку возврата в меню
    
    Returns:
        Словарь с inline keyboard markup
    """
    status_buttons = [
        [{'text': '⏳ Ожидает', 'callback_data': f'order_status_{order_id}_pending'}],
        [{'text': '🔄 Обрабатывается', 'callback_data': f'order_status_{order_id}_processing'}],
        [{'text': '✅ Завершен', 'callback_data': f'order_status_{order_id}_completed'}],
        [{'text': '❌ Отменен', 'callback_data': f'order_status_{order_id}_cancelled'}],
    ]
    
    # Отмечаем текущий статус
    status_map = {
        'pending': 0,
        'processing': 1,
        'completed': 2,
        'cancelled': 3,
    }
    
    if current_status in status_map:
        idx = status_map[current_status]
        # Добавляем галочку к текущему статусу
        status_buttons[idx][0]['text'] = f"✓ {status_buttons[idx][0]['text']}"
    
    # Добавляем кнопку возврата в меню, если нужно
    if include_menu_button:
        status_buttons.append([{'text': '🔙 Главное меню', 'callback_data': 'menu_main'}])
    
    return {
        'inline_keyboard': status_buttons
    }


def notify_new_order(order) -> None:
    """Уведомить о новом заказе."""
    bot_settings = TelegramAdminBotSettings.get_settings()
    
    if not bot_settings.enabled or not bot_settings.notify_new_order:
        return
    
    # Получаем элементы заказа с оптимизацией запросов
    # Важно: перезагружаем order из БД, чтобы получить свежие order_items
    try:
        from core.models import Order
        # Перезагружаем заказ с prefetch_related для оптимизации
        order = Order.objects.prefetch_related('order_items__menu_item').get(pk=order.pk)
        order_items = list(order.order_items.all())
    except Exception as e:
        logger.error(f"Error loading order items for order {order.id}: {str(e)}")
        # Пробуем загрузить без оптимизации
        try:
            order_items = list(order.order_items.all())
        except Exception as e2:
            logger.error(f"Error loading order items (fallback) for order {order.id}: {str(e2)}")
            order_items = []
    
    # Формируем список блюд
    if order_items:
        items_list = []
        for item in order_items:
            try:
                # Загружаем menu_item если не загружен
                if not hasattr(item, '_menu_item_loaded'):
                    try:
                        item.menu_item  # Триггерим загрузку
                    except:
                        pass
                
                item_name = item.menu_item.name if item.menu_item else f"Блюдо #{item.menu_item_id}"
                item_price = float(item.menu_item.price) if item.menu_item and item.menu_item.price else 0
                subtotal = item_price * item.quantity
                items_list.append(f"  • {item_name} × {item.quantity} = {subtotal:.2f}€")
            except Exception as e:
                logger.error(f"Error processing order item {item.id}: {str(e)}")
                items_list.append(f"  • Блюдо #{item.menu_item_id} × {item.quantity} (ошибка получения данных)")
        items_text = "\n".join(items_list) if items_list else "  (Блюда не найдены)"
    else:
        items_text = "  (Блюда не найдены)"
        logger.warning(f"No order items found for order {order.id}")
    
    # Определяем адрес доставки
    if order.is_pickup:
        address_text = "🚶 <b>Самовывоз</b>"
    elif order.postal_code or order.address:
        address_text = f"{order.postal_code or ''} {order.address or ''}".strip()
    else:
        address_text = "Не указано"
    
    message = f"""
🆕 <b>Новый заказ #{order.id}</b>

👤 <b>Клиент:</b> {order.name or 'Не указано'}
📧 <b>Email:</b> {order.email or 'Не указано'}
📱 <b>Телефон:</b> {order.phone or 'Не указано'}

📍 <b>Адрес:</b> {address_text}

🛒 <b>Блюда:</b>
{items_text}

💰 <b>Итого:</b> {order.get_total():.2f}€
🚚 <b>Доставка:</b> {order.delivery_cost:.2f}€

📝 <b>Комментарий:</b> {order.comment or 'Нет комментария'}

⏰ <b>Дата:</b> {order.created_at.strftime('%d.%m.%Y %H:%M')}

📊 <b>Статус:</b> {dict(order.STATUS_CHOICES).get(order.status, order.status)}
"""
    
    # Создаем keyboard для управления статусом (без кнопки меню, так как это уведомление)
    keyboard = get_order_status_keyboard(order.id, order.status, include_menu_button=False)
    
    # Добавляем кнопку перехода к списку заказов
    orders_button = [{'text': '📋 К списку заказов', 'callback_data': 'menu_orders_page_0'}]
    if 'inline_keyboard' in keyboard:
        keyboard['inline_keyboard'].append(orders_button)
    
    # Отправляем сообщение с кнопками каждому авторизованному админу
    authorized_admins = TelegramAdmin.objects.filter(authorized=True)
    for admin in authorized_admins:
        send_telegram_message(admin.telegram_chat_id, message.strip(), reply_markup=keyboard)


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

