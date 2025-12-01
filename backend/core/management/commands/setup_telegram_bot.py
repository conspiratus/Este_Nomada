"""
Management команда для настройки Telegram бота.
"""
from django.core.management.base import BaseCommand
from core.models import TelegramAdminBotSettings
import requests
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Настроить Telegram бота: установить токен и вебхук'

    def add_arguments(self, parser):
        parser.add_argument(
            '--token',
            type=str,
            help='Токен бота от @BotFather',
        )
        parser.add_argument(
            '--webhook-url',
            type=str,
            help='URL для вебхука (например, https://example.com/api/telegram/webhook/)',
        )
        parser.add_argument(
            '--enable',
            action='store_true',
            help='Включить бота после настройки',
        )

    def handle(self, *args, **options):
        bot_settings = TelegramAdminBotSettings.get_settings()
        
        # Устанавливаем токен
        if options['token']:
            bot_settings.bot_token = options['token']
            bot_settings.save()
            self.stdout.write(
                self.style.SUCCESS(f'✓ Токен установлен: {options["token"][:10]}...')
            )
        elif not bot_settings.bot_token:
            self.stdout.write(
                self.style.WARNING('⚠ Токен не указан. Используйте --token для установки.')
            )
        
        # Настраиваем вебхук
        if options['webhook_url']:
            webhook_url = options['webhook_url']
            token = bot_settings.bot_token
            
            if not token:
                self.stdout.write(
                    self.style.ERROR('❌ Токен не установлен. Сначала установите токен с помощью --token')
                )
                return
            
            try:
                # Устанавливаем вебхук
                url = f"https://api.telegram.org/bot{token}/setWebhook"
                response = requests.post(url, json={'url': webhook_url}, timeout=10)
                response.raise_for_status()
                
                result = response.json()
                if result.get('ok'):
                    self.stdout.write(
                        self.style.SUCCESS(f'✓ Вебхук установлен: {webhook_url}')
                    )
                    
                    # Проверяем информацию о вебхуке
                    info_url = f"https://api.telegram.org/bot{token}/getWebhookInfo"
                    info_response = requests.get(info_url, timeout=10)
                    info_response.raise_for_status()
                    info = info_response.json()
                    
                    if info.get('ok'):
                        webhook_info = info.get('result', {})
                        self.stdout.write(f'  URL: {webhook_info.get("url", "не установлен")}')
                        self.stdout.write(f'  Ожидает обновлений: {webhook_info.get("pending_update_count", 0)}')
                        if webhook_info.get('last_error_date'):
                            self.stdout.write(
                                self.style.WARNING(f'  ⚠ Последняя ошибка: {webhook_info.get("last_error_message", "неизвестно")}')
                            )
                else:
                    self.stdout.write(
                        self.style.ERROR(f'❌ Ошибка установки вебхука: {result.get("description", "неизвестно")}')
                    )
                    
            except requests.exceptions.RequestException as e:
                self.stdout.write(
                    self.style.ERROR(f'❌ Ошибка при установке вебхука: {str(e)}')
                )
        else:
            self.stdout.write(
                self.style.WARNING('⚠ URL вебхука не указан. Используйте --webhook-url для установки.')
            )
        
        # Включаем бота
        if options['enable']:
            bot_settings.enabled = True
            bot_settings.save()
            self.stdout.write(
                self.style.SUCCESS('✓ Бот включен')
            )
        
        # Показываем текущие настройки
        self.stdout.write('\n' + '='*50)
        self.stdout.write('Текущие настройки:')
        self.stdout.write(f'  Токен: {"✓ установлен" if bot_settings.bot_token else "✗ не установлен"}')
        self.stdout.write(f'  Включен: {"✓ да" if bot_settings.enabled else "✗ нет"}')
        self.stdout.write('='*50)
        
        if bot_settings.bot_token and not options['webhook_url']:
            self.stdout.write('\nДля установки вебхука выполните:')
            self.stdout.write(
                self.style.SUCCESS(
                    f'  python manage.py setup_telegram_bot --webhook-url https://ваш-домен.com/api/telegram/webhook/'
                )
            )

