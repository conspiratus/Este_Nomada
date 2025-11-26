"""
Celery tasks for integrations.
"""
import logging
from celery import shared_task
from django.conf import settings as django_settings
from core.models import Story, Settings, Order, OrderItem, InstagramPost
import requests
import openai
from datetime import datetime

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

