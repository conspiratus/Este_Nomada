# Generated manually on 2025-01-XX

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0035_add_account_translations'),
    ]

    operations = [
        migrations.CreateModel(
            name='OrderReview',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rating', models.IntegerField(help_text='Оценка от 1 до 5 звезд', validators=[django.core.validators.MinValueValidator(1), django.core.validators.MaxValueValidator(5)], verbose_name='Оценка (1-5)')),
                ('comment', models.TextField(blank=True, help_text='Текстовый отзыв о заказе', null=True, verbose_name='Комментарий')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
                ('order', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='review', to='core.order', verbose_name='Заказ')),
            ],
            options={
                'verbose_name': 'Отзыв на заказ',
                'verbose_name_plural': 'Отзывы на заказы',
                'db_table': 'order_reviews',
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='orderreview',
            index=models.Index(fields=['order'], name='order_revie_order_i_idx'),
        ),
        migrations.AddIndex(
            model_name='orderreview',
            index=models.Index(fields=['rating'], name='order_revie_rating_idx'),
        ),
    ]

