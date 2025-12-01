"""
Celery tasks for integrations.
"""
import logging
from celery import shared_task
from django.conf import settings as django_settings
from core.models import (
    Story, Settings, Order, OrderItem, InstagramPost,
    TelegramAdminBotSettings, Stock, IngredientStock, Ingredient
)
from core.telegram_utils import send_notification_to_authorized_admins
import requests
import openai
from datetime import datetime, time
from decimal import Decimal

logger = logging.getLogger(__name__)


@shared_task
def sync_telegram_channel():
    """Синхронизация постов из Telegram канала."""
    try:
        settings_obj = Settings.get_settings()
        
        if not settings_obj.bot_token or not settings_obj.channel_id:
            logger.warning("Telegram credentials not configured")
            return
        
        # Здесь будет логика получения постов из Telegram
        # Используем Telegram Bot API
        bot_token = settings_obj.bot_token
        channel_id = settings_obj.channel_id
        
        # Пример запроса к Telegram API
        url = f"https://api.telegram.org/bot{bot_token}/getUpdates"
        # Реальная логика будет зависеть от типа канала (публичный/приватный)
        
        logger.info("Telegram sync completed")
        return {"status": "success", "message": "Telegram sync completed"}
        
    except Exception as e:
        logger.error(f"Error syncing Telegram: {str(e)}")
        return {"status": "error", "message": str(e)}


@shared_task
def process_order_with_ai(order_id):
    """Обработка заказа через OpenAI."""
    try:
        order = Order.objects.get(id=order_id)
        
        if not django_settings.OPENAI_API_KEY:
            logger.warning("OpenAI API key not configured")
            return
        
        # Получаем информацию о заказе
        order_items = order.order_items.all()
        dishes = [item.menu_item.name for item in order_items]
        
        # Формируем промпт для ChatGPT
        prompt = f"""
        Обработай заказ от клиента:
        Имя: {order.name}
        Телефон: {order.phone}
        Блюда: {', '.join(dishes)}
        Комментарий: {order.comment or 'Нет комментария'}
        
        Создай дружелюбный ответ на русском языке, подтверждающий заказ и уточняющий детали.
        """
        
        # Вызов OpenAI API
        client = openai.OpenAI(api_key=django_settings.OPENAI_API_KEY)
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "Ты помощник ресторана Este Nómada. Отвечай дружелюбно на русском языке."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=200,
            temperature=0.7
        )
        
        ai_response = response.choices[0].message.content
        order.ai_response = ai_response
        order.status = 'processing'
        order.save()
        
        logger.info(f"Order {order_id} processed with AI")
        return {"status": "success", "ai_response": ai_response}
        
    except Exception as e:
        logger.error(f"Error processing order with AI: {str(e)}")
        return {"status": "error", "message": str(e)}


@shared_task
def sync_instagram_feed():
    """Синхронизация постов из Instagram."""
    try:
        if not django_settings.INSTAGRAM_ACCESS_TOKEN:
            logger.warning("Instagram access token not configured")
            return
        
        access_token = django_settings.INSTAGRAM_ACCESS_TOKEN
        
        # Запрос к Instagram Basic Display API
        url = f"https://graph.instagram.com/me/media"
        params = {
            'fields': 'id,caption,media_type,media_url,permalink,timestamp',
            'access_token': access_token
        }
        
        response = requests.get(url, params=params)
        response.raise_for_status()
        
        data = response.json()
        
        # Сохраняем посты в БД
        for item in data.get('data', []):
            instagram_id = item.get('id')
            
            # Проверяем, не существует ли уже
            if not InstagramPost.objects.filter(instagram_id=instagram_id).exists():
                InstagramPost.objects.create(
                    instagram_id=instagram_id,
                    caption=item.get('caption', ''),
                    media_url=item.get('media_url', ''),
                    media_type=item.get('media_type', 'IMAGE'),
                    permalink=item.get('permalink', ''),
                    timestamp=datetime.fromisoformat(item.get('timestamp', '').replace('Z', '+00:00'))
                )
        
        logger.info("Instagram sync completed")
        return {"status": "success", "count": len(data.get('data', []))}
        
    except Exception as e:
        logger.error(f"Error syncing Instagram: {str(e)}")
        return {"status": "error", "message": str(e)}


@shared_task
def send_daily_stock_report():
    """Отправка ежедневного отчета о остатках блюд и ингредиентов."""
    try:
        bot_settings = TelegramAdminBotSettings.get_settings()
        
        if not bot_settings.enabled or not bot_settings.daily_reports_enabled:
            logger.debug("Daily stock reports are disabled")
            return {"status": "skipped", "message": "Reports disabled"}
        
        # Проверяем остатки блюд
        low_stock_items = []
        for stock in Stock.objects.all():
            total = stock.get_total_quantity()
            if total < bot_settings.menu_item_low_stock_threshold:
                low_stock_items.append({
                    'name': stock.menu_item.name,
                    'quantity': total,
                    'threshold': bot_settings.menu_item_low_stock_threshold
                })
        
        # Проверяем остатки ингредиентов
        low_stock_ingredients = []
        for ingredient_stock in IngredientStock.objects.select_related('ingredient').all():
            threshold = bot_settings.get_threshold_for_unit(ingredient_stock.ingredient.unit)
            if ingredient_stock.quantity < Decimal(str(threshold)):
                unit_display = dict(ingredient_stock.ingredient.UNIT_CHOICES).get(
                    ingredient_stock.ingredient.unit,
                    ingredient_stock.ingredient.unit
                )
                low_stock_ingredients.append({
                    'name': ingredient_stock.ingredient.name,
                    'quantity': float(ingredient_stock.quantity),
                    'unit': unit_display,
                    'threshold': float(threshold)
                })
        
        # Формируем сообщение
        message_parts = ["📊 <b>Ежедневный отчет об остатках</b>\n"]
        
        if low_stock_items:
            message_parts.append("🍽️ <b>Блюда с низким остатком:</b>")
            for item in low_stock_items:
                message_parts.append(
                    f"  ⚠️ {item['name']}: {item['quantity']} порций "
                    f"(порог: {item['threshold']})"
                )
            message_parts.append("")
        else:
            message_parts.append("✅ <b>Блюда:</b> Все в норме\n")
        
        if low_stock_ingredients:
            message_parts.append("🥘 <b>Ингредиенты с низким остатком:</b>")
            for ing in low_stock_ingredients:
                message_parts.append(
                    f"  ⚠️ {ing['name']}: {ing['quantity']} {ing['unit']} "
                    f"(порог: {ing['threshold']} {ing['unit']})"
                )
        else:
            message_parts.append("✅ <b>Ингредиенты:</b> Все в норме")
        
        message = "\n".join(message_parts)
        
        # Отправляем уведомления
        sent_count = send_notification_to_authorized_admins(message)
        
        logger.info(f"Daily stock report sent to {sent_count} admins")
        return {
            "status": "success",
            "sent_to": sent_count,
            "low_stock_items": len(low_stock_items),
            "low_stock_ingredients": len(low_stock_ingredients)
        }
        
    except Exception as e:
        logger.error(f"Error sending daily stock report: {str(e)}")
        return {"status": "error", "message": str(e)}

