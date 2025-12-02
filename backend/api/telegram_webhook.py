"""
Обработчик вебхука для Telegram бота.
"""
import logging
import json
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from core.models import TelegramAdminBotSettings, TelegramAdmin, Order
from core.telegram_utils import (
    answer_callback_query,
    edit_message_text,
    get_order_status_keyboard,
    send_telegram_message,
    get_main_menu_keyboard,
    get_orders_list_keyboard,
    format_order_details
)

logger = logging.getLogger(__name__)


@csrf_exempt
@require_http_methods(["POST"])
def telegram_webhook(request):
    """
    Обработчик вебхука от Telegram.
    """
    try:
        data = json.loads(request.body)
        logger.debug(f"Received Telegram update: {json.dumps(data, indent=2)}")
        
        # Проверяем, что бот включен
        bot_settings = TelegramAdminBotSettings.get_settings()
        if not bot_settings.enabled or not bot_settings.bot_token:
            logger.debug("Telegram bot is disabled")
            return JsonResponse({'ok': True})  # Возвращаем ok, чтобы Telegram не повторял запрос
        
        # Обрабатываем callback query (нажатие на inline кнопку)
        if 'callback_query' in data:
            handle_callback_query(data['callback_query'])
        
        # Обрабатываем обычные сообщения (команды)
        elif 'message' in data:
            handle_message(data['message'])
        
        return JsonResponse({'ok': True})
        
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in webhook: {str(e)}")
        return JsonResponse({'ok': False, 'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        logger.error(f"Error processing webhook: {str(e)}", exc_info=True)
        return JsonResponse({'ok': False, 'error': str(e)}, status=500)


def handle_callback_query(callback_query: dict):
    """
    Обработать callback query (нажатие на inline кнопку).
    """
    try:
        callback_id = callback_query['id']
        chat_id = callback_query['message']['chat']['id']
        message_id = callback_query['message']['message_id']
        callback_data = callback_query['data']
        user_id = callback_query['from']['id']
        
        logger.info(f"Callback query from user {user_id}: {callback_data}")
        
        # Проверяем, что пользователь не забанен и авторизован
        try:
            admin = TelegramAdmin.objects.get(telegram_chat_id=user_id)
            if admin.banned:
                answer_callback_query(callback_id, "❌ Вы заблокированы и не можете использовать этого бота", show_alert=True)
                return
            if not admin.authorized:
                answer_callback_query(callback_id, "❌ Вы не авторизованы для управления заказами", show_alert=True)
                return
        except TelegramAdmin.DoesNotExist:
            answer_callback_query(callback_id, "❌ Вы не зарегистрированы. Используйте /start для регистрации", show_alert=True)
            return
        
        # Обрабатываем изменение статуса заказа
        if callback_data.startswith('order_status_'):
            parts = callback_data.split('_')
            if len(parts) == 4:
                order_id = int(parts[2])
                new_status = parts[3]
                handle_order_status_change(callback_id, chat_id, message_id, order_id, new_status, callback_query['message']['text'])
            else:
                answer_callback_query(callback_id, "❌ Неверный формат команды", show_alert=True)
        # Главное меню
        elif callback_data == 'menu_main':
            handle_main_menu(callback_id, chat_id, message_id)
        # Список заказов
        elif callback_data.startswith('menu_orders_page_'):
            page = int(callback_data.split('_')[3])
            handle_orders_list(callback_id, chat_id, message_id, page)
        # Детали заказа
        elif callback_data.startswith('order_detail_'):
            order_id = int(callback_data.split('_')[2])
            handle_order_detail(callback_id, chat_id, message_id, order_id)
        # Готовая продукция (заглушка)
        elif callback_data == 'menu_stock':
            answer_callback_query(callback_id, "🍽️ Раздел 'Готовая продукция' в разработке", show_alert=True)
        # Склад (заглушка)
        elif callback_data == 'menu_warehouse':
            answer_callback_query(callback_id, "📦 Раздел 'Склад' в разработке", show_alert=True)
        else:
            answer_callback_query(callback_id, "❌ Неизвестная команда", show_alert=True)
            
    except Exception as e:
        logger.error(f"Error handling callback query: {str(e)}", exc_info=True)
        if 'callback_id' in locals():
            answer_callback_query(callback_id, "❌ Ошибка при обработке запроса", show_alert=True)


def handle_order_status_change(callback_id: str, chat_id: int, message_id: int, order_id: int, new_status: str, current_message_text: str):
    """
    Обработать изменение статуса заказа.
    """
    try:
        # Получаем заказ
        try:
            order = Order.objects.get(pk=order_id)
        except Order.DoesNotExist:
            answer_callback_query(callback_id, f"❌ Заказ #{order_id} не найден", show_alert=True)
            return
        
        # Проверяем валидность статуса
        valid_statuses = [choice[0] for choice in Order.STATUS_CHOICES]
        if new_status not in valid_statuses:
            answer_callback_query(callback_id, f"❌ Неверный статус: {new_status}", show_alert=True)
            return
        
        # Сохраняем старый статус для уведомления
        old_status = order.status
        
        # Обновляем статус
        order.status = new_status
        order.save()
        
        # Обновляем сообщение с новым статусом
        # Заменяем строку со статусом в тексте сообщения
        status_names = dict(Order.STATUS_CHOICES)
        old_status_text = f"📊 <b>Статус:</b> {status_names.get(old_status, old_status)}"
        new_status_text = f"📊 <b>Статус:</b> {status_names.get(new_status, new_status)}"
        
        updated_message = current_message_text.replace(old_status_text, new_status_text)
        
        # Обновляем keyboard (включая кнопку меню)
        keyboard = get_order_status_keyboard(order.id, new_status, include_menu_button=True)
        
        # Редактируем сообщение
        edit_message_text(chat_id, message_id, updated_message, reply_markup=keyboard)
        
        # Отвечаем на callback
        answer_callback_query(callback_id, f"✅ Статус изменен на: {status_names.get(new_status, new_status)}")
        
        logger.info(f"Order {order_id} status changed from {old_status} to {new_status} by Telegram admin")
        
    except Exception as e:
        logger.error(f"Error changing order status: {str(e)}", exc_info=True)
        answer_callback_query(callback_id, f"❌ Ошибка: {str(e)}", show_alert=True)


def handle_message(message: dict):
    """
    Обработать обычное сообщение (команды).
    """
    try:
        chat_id = message['chat']['id']
        user_id = message['from']['id']
        text = message.get('text', '')
        from_user = message.get('from', {})
        
        logger.info(f"Message from user {user_id} in chat {chat_id}: {text}")
        
        # Обрабатываем команды
        if text.startswith('/'):
            command = text.split()[0] if text.split() else text
            
            if command == '/start' or command == '/menu':
                # Автоматически создаем или обновляем запись в TelegramAdmin
                admin, created = TelegramAdmin.objects.get_or_create(
                    telegram_chat_id=user_id,
                    defaults={
                        'username': from_user.get('username'),
                        'first_name': from_user.get('first_name'),
                        'last_name': from_user.get('last_name'),
                        'authorized': False,
                        'banned': False,
                    }
                )
                
                # Обновляем информацию о пользователе, если запись уже существовала
                if not created:
                    admin.username = from_user.get('username') or admin.username
                    admin.first_name = from_user.get('first_name') or admin.first_name
                    admin.last_name = from_user.get('last_name') or admin.last_name
                    admin.save()
                
                # Проверяем, не забанен ли пользователь
                if admin.banned:
                    send_telegram_message(chat_id, "❌ Вы заблокированы и не можете использовать этого бота.", check_banned=False)
                    return
                
                # Проверяем авторизацию
                if not admin.authorized:
                    send_telegram_message(chat_id, """
👋 <b>Добро пожаловать!</b>

Ваш запрос на доступ к боту зарегистрирован.

Ожидайте авторизации администратором. После авторизации вы сможете использовать все функции бота.
""", check_banned=False)
                    logger.info(f"New user {user_id} registered, waiting for authorization")
                    return
                
                # Отправляем главное меню для авторизованных
                keyboard = get_main_menu_keyboard()
                send_telegram_message(chat_id, """
👋 <b>Добро пожаловать в админский бот Este Nómada!</b>

Выберите раздел:
""", reply_markup=keyboard, check_banned=False)
            elif command == '/help':
                # Проверяем авторизацию и бан
                try:
                    admin = TelegramAdmin.objects.get(telegram_chat_id=user_id)
                    if admin.banned:
                        send_telegram_message(chat_id, "❌ Вы заблокированы и не можете использовать этого бота.", check_banned=False)
                        return
                    if not admin.authorized:
                        send_telegram_message(chat_id, "❌ Вы не авторизованы для использования этого бота. Ожидайте авторизации администратором.", check_banned=False)
                        return
                except TelegramAdmin.DoesNotExist:
                    send_telegram_message(chat_id, "❌ Вы не зарегистрированы. Используйте /start для регистрации.", check_banned=False)
                    return
                
                keyboard = get_main_menu_keyboard()
                send_telegram_message(chat_id, """
📖 <b>Доступные команды:</b>

/start или /menu - Главное меню
/help - Показать эту справку

<b>Управление заказами:</b>
Используйте кнопки в уведомлениях о заказах или главное меню для управления заказами.
""", reply_markup=keyboard, check_banned=False)
            else:
                # Проверяем авторизацию для других команд
                try:
                    admin = TelegramAdmin.objects.get(telegram_chat_id=user_id)
                    if admin.banned:
                        send_telegram_message(chat_id, "❌ Вы заблокированы и не можете использовать этого бота.", check_banned=False)
                        return
                    if not admin.authorized:
                        send_telegram_message(chat_id, "❌ Вы не авторизованы для использования этого бота.", check_banned=False)
                        return
                except TelegramAdmin.DoesNotExist:
                    send_telegram_message(chat_id, "❌ Вы не зарегистрированы. Используйте /start для регистрации.", check_banned=False)
                    return
                
                send_telegram_message(chat_id, f"❌ Неизвестная команда: {command}\n\nИспользуйте /help для справки.", check_banned=False)
        
    except Exception as e:
        logger.error(f"Error handling message: {str(e)}", exc_info=True)


def handle_main_menu(callback_id: str, chat_id: int, message_id: int):
    """
    Показать главное меню.
    """
    try:
        keyboard = get_main_menu_keyboard()
        message = """
👋 <b>Главное меню</b>

Выберите раздел:
"""
        edit_message_text(chat_id, message_id, message, reply_markup=keyboard)
        answer_callback_query(callback_id)
    except Exception as e:
        logger.error(f"Error showing main menu: {str(e)}", exc_info=True)
        answer_callback_query(callback_id, "❌ Ошибка при отображении меню", show_alert=True)


def handle_orders_list(callback_id: str, chat_id: int, message_id: int, page: int):
    """
    Показать список заказов с пагинацией.
    """
    try:
        keyboard, message = get_orders_list_keyboard(page)
        edit_message_text(chat_id, message_id, message, reply_markup=keyboard)
        answer_callback_query(callback_id)
    except Exception as e:
        logger.error(f"Error showing orders list: {str(e)}", exc_info=True)
        answer_callback_query(callback_id, f"❌ Ошибка: {str(e)}", show_alert=True)


def handle_order_detail(callback_id: str, chat_id: int, message_id: int, order_id: int):
    """
    Показать детали заказа.
    """
    try:
        # Получаем заказ
        try:
            order = Order.objects.prefetch_related('order_items__menu_item').get(pk=order_id)
        except Order.DoesNotExist:
            answer_callback_query(callback_id, f"❌ Заказ #{order_id} не найден", show_alert=True)
            return
        
        # Форматируем детали заказа
        message = format_order_details(order)
        
        # Создаем keyboard с кнопками управления статусом
        # include_menu_button=True, чтобы всегда была кнопка возврата в меню
        status_keyboard = get_order_status_keyboard(order.id, order.status, include_menu_button=True)
        
        # Добавляем кнопку возврата к списку заказов перед кнопкой меню
        orders_button = [{'text': '🔙 К списку заказов', 'callback_data': 'menu_orders_page_0'}]
        if 'inline_keyboard' in status_keyboard:
            # Вставляем кнопку перед последней (главное меню)
            status_keyboard['inline_keyboard'].insert(-1, orders_button)
        else:
            status_keyboard['inline_keyboard'] = [orders_button]
        
        # Редактируем сообщение (всегда редактируем существующее, не создаем новое)
        edit_message_text(chat_id, message_id, message, reply_markup=status_keyboard)
        answer_callback_query(callback_id)
        
    except Exception as e:
        logger.error(f"Error showing order detail: {str(e)}", exc_info=True)
        answer_callback_query(callback_id, f"❌ Ошибка: {str(e)}", show_alert=True)

