"""
URLs для Telegram вебхука.
"""
from django.urls import path
from .telegram_webhook import telegram_webhook

urlpatterns = [
    path('', telegram_webhook, name='telegram_webhook'),
]

