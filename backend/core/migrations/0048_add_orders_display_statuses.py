# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0047_merge_telegram_and_ttk'),
    ]

    operations = [
        migrations.AddField(
            model_name='telegramadminbotsettings',
            name='orders_display_statuses',
            field=models.CharField(
                default='pending,processing',
                help_text='Статусы заказов, которые будут отображаться в разделе "Текущие заказы" (через запятую: pending,processing,completed,cancelled)',
                max_length=255,
                verbose_name='Статусы заказов для отображения'
            ),
        ),
    ]

