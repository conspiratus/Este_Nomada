# Generated manually on 2025-11-28

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0031_add_all_translations_from_json'),
    ]

    operations = [
        # Изменяем поля в модели Order на EncryptedField
        migrations.AlterField(
            model_name='order',
            name='name',
            field=models.TextField(blank=True, null=True, verbose_name='Имя'),
        ),
        migrations.AlterField(
            model_name='order',
            name='postal_code',
            field=models.TextField(blank=True, null=True, verbose_name='Почтовый индекс'),
        ),
        migrations.AlterField(
            model_name='order',
            name='address',
            field=models.TextField(blank=True, null=True, verbose_name='Адрес доставки'),
        ),
        # Изменяем поля в модели Customer на EncryptedField
        migrations.AlterField(
            model_name='customer',
            name='name',
            field=models.TextField(blank=True, null=True, verbose_name='Имя'),
        ),
        migrations.AlterField(
            model_name='customer',
            name='postal_code',
            field=models.TextField(blank=True, null=True, verbose_name='Почтовый индекс'),
        ),
        migrations.AlterField(
            model_name='customer',
            name='address',
            field=models.TextField(blank=True, null=True, verbose_name='Адрес'),
        ),
    ]

