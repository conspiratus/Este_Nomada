# Generated manually on 2025-11-28

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0033_add_preferred_locale_to_customer'),
    ]

    operations = [
        migrations.CreateModel(
            name='HeroButton',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('order', models.IntegerField(default=0, help_text='Чем меньше число, тем раньше кнопка отображается', validators=[django.core.validators.MinValueValidator(0)], verbose_name='Порядок отображения')),
                ('url', models.CharField(help_text='Может быть относительным (/ru/stories) или абсолютным (https://t.me/este_nomada)', max_length=500, verbose_name='URL ссылки')),
                ('style', models.CharField(choices=[('primary', 'Основная (Primary) - Залитая кнопка'), ('secondary', 'Вторичная (Secondary) - С рамкой'), ('outline', 'Контурная (Outline) - Прозрачная с рамкой'), ('ghost', 'Призрачная (Ghost) - Без рамки')], default='primary', help_text='Визуальный стиль кнопки', max_length=20, verbose_name='Стиль кнопки')),
                ('active', models.BooleanField(default=True, help_text='Показывать ли кнопку на сайте', verbose_name='Активна')),
                ('open_in_new_tab', models.BooleanField(default=False, help_text='Добавляет target="_blank" к ссылке', verbose_name='Открывать в новой вкладке')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'Кнопка Hero',
                'verbose_name_plural': 'Кнопки Hero',
                'db_table': 'hero_buttons',
                'ordering': ['order', 'created_at'],
            },
        ),
        migrations.CreateModel(
            name='HeroButtonTranslation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('locale', models.CharField(max_length=10, verbose_name='Локаль')),
                ('text', models.CharField(help_text='Текст, который будет отображаться на кнопке', max_length=255, verbose_name='Текст кнопки')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('button', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='translations', to='core.herobutton', verbose_name='Кнопка')),
            ],
            options={
                'verbose_name': 'Перевод кнопки Hero',
                'verbose_name_plural': 'Переводы кнопок Hero',
                'db_table': 'hero_button_translations',
                'unique_together': {('button', 'locale')},
            },
        ),
        migrations.AddIndex(
            model_name='herobutton',
            index=models.Index(fields=['active', 'order'], name='hero_button_active_order_idx'),
        ),
        migrations.AddIndex(
            model_name='herobuttontranslation',
            index=models.Index(fields=['button', 'locale'], name='hero_button_button_locale_idx'),
        ),
    ]

