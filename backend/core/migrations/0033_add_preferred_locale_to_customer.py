# Generated manually on 2025-11-28

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0032_encrypt_personal_data'),
    ]

    operations = [
        migrations.AddField(
            model_name='customer',
            name='preferred_locale',
            field=models.CharField(
                blank=True,
                choices=[('ru', 'Русский'), ('es', 'Español'), ('en', 'English')],
                default='ru',
                max_length=10,
                null=True,
                verbose_name='Предпочитаемый язык'
            ),
        ),
    ]

