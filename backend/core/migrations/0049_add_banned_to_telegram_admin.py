# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0048_add_orders_display_statuses'),
    ]

    operations = [
        migrations.AddField(
            model_name='telegramadmin',
            name='banned',
            field=models.BooleanField(
                default=False,
                help_text='Если включено, бот не будет отправлять этому пользователю никакие сообщения',
                verbose_name='Забанен'
            ),
        ),
        migrations.AlterField(
            model_name='telegramadmin',
            name='user',
            field=models.OneToOneField(
                blank=True,
                help_text='Связь с пользователем Django (опционально)',
                null=True,
                on_delete=models.SET_NULL,
                related_name='telegram_admin',
                to='auth.user',
                verbose_name='Пользователь'
            ),
        ),
    ]

