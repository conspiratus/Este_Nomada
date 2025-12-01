# Generated manually on 2025-11-30

from django.db import migrations, models
import django.db.models.deletion
from django.core.validators import MinValueValidator


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0044_add_price_source'),
        ('core', '0045_rename_hero_button_active_order_idx_hero_button_active_e451a7_idx_and_more'),
        ('auth', '0012_alter_user_first_name_max_length'),
    ]

    operations = [
        migrations.CreateModel(
            name='TelegramAdminBotSettings',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('bot_token', models.TextField(blank=True, help_text='Токен бота от @BotFather', null=True, verbose_name='Токен бота')),
                ('enabled', models.BooleanField(default=False, help_text='Включить отправку уведомлений через бота', verbose_name='Включен')),
                ('notify_new_order', models.BooleanField(default=True, verbose_name='Уведомлять о новых заказах')),
                ('notify_order_status_change', models.BooleanField(default=True, verbose_name='Уведомлять об изменении статуса заказа')),
                ('notify_new_customer', models.BooleanField(default=True, verbose_name='Уведомлять о новых пользователях')),
                ('notify_review', models.BooleanField(default=True, verbose_name='Уведомлять об отзывах')),
                ('daily_reports_enabled', models.BooleanField(default=True, verbose_name='Включить ежедневные отчеты')),
                ('daily_reports_time', models.TimeField(default='09:00', help_text='Время отправки ежедневных отчетов (часовой пояс сервера)', verbose_name='Время отправки отчетов')),
                ('menu_item_low_stock_threshold', models.IntegerField(default=5, help_text='Минимальное количество порций для предупреждения', validators=[MinValueValidator(0)], verbose_name='Порог низкого остатка блюд (порций)')),
                ('ingredient_threshold_kg', models.DecimalField(decimal_places=3, default=1.0, help_text='Порог низкого остатка для ингредиентов в килограммах', max_digits=10, validators=[MinValueValidator(0)], verbose_name='Порог для кг')),
                ('ingredient_threshold_g', models.DecimalField(decimal_places=3, default=500.0, help_text='Порог низкого остатка для ингредиентов в граммах', max_digits=10, validators=[MinValueValidator(0)], verbose_name='Порог для г')),
                ('ingredient_threshold_l', models.DecimalField(decimal_places=3, default=1.0, help_text='Порог низкого остатка для ингредиентов в литрах', max_digits=10, validators=[MinValueValidator(0)], verbose_name='Порог для л')),
                ('ingredient_threshold_ml', models.DecimalField(decimal_places=3, default=500.0, help_text='Порог низкого остатка для ингредиентов в миллилитрах', max_digits=10, validators=[MinValueValidator(0)], verbose_name='Порог для мл')),
                ('ingredient_threshold_pcs', models.DecimalField(decimal_places=3, default=10.0, help_text='Порог низкого остатка для поштучных товаров', max_digits=10, validators=[MinValueValidator(0)], verbose_name='Порог для шт/уп/банка/бутылка')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
            ],
            options={
                'verbose_name': 'Настройки админского Telegram бота',
                'verbose_name_plural': 'Настройки админского Telegram бота',
                'db_table': 'telegram_admin_bot_settings',
            },
        ),
        migrations.CreateModel(
            name='TelegramAdmin',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('telegram_chat_id', models.BigIntegerField(help_text='ID чата пользователя в Telegram', unique=True, verbose_name='Telegram Chat ID')),
                ('authorized', models.BooleanField(default=False, help_text='Пользователь подтвержден для получения уведомлений', verbose_name='Авторизован')),
                ('username', models.CharField(blank=True, help_text='Имя пользователя в Telegram (если есть)', max_length=255, null=True, verbose_name='Telegram Username')),
                ('first_name', models.CharField(blank=True, max_length=255, null=True, verbose_name='Имя в Telegram')),
                ('last_name', models.CharField(blank=True, max_length=255, null=True, verbose_name='Фамилия в Telegram')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='telegram_admin', to='auth.user', verbose_name='Пользователь')),
            ],
            options={
                'verbose_name': 'Админ Telegram бота',
                'verbose_name_plural': 'Админы Telegram бота',
                'db_table': 'telegram_admin',
            },
        ),
        migrations.AddIndex(
            model_name='telegramadmin',
            index=models.Index(fields=['telegram_chat_id'], name='telegram_ad_chat_id_idx'),
        ),
        migrations.AddIndex(
            model_name='telegramadmin',
            index=models.Index(fields=['authorized'], name='telegram_ad_authoriz_idx'),
        ),
    ]

