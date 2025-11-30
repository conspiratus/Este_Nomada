# Generated manually on 2025-11-29

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0039_add_missing_status_translations'),
    ]

    operations = [
        # Создаем модель Supplier
        migrations.CreateModel(
            name='Supplier',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, verbose_name='Название поставщика')),
                ('contact_person', models.CharField(blank=True, max_length=255, null=True, verbose_name='Контактное лицо')),
                ('phone', models.CharField(blank=True, max_length=50, null=True, verbose_name='Телефон')),
                ('email', models.EmailField(blank=True, max_length=254, null=True, verbose_name='Email')),
                ('address', models.TextField(blank=True, null=True, verbose_name='Адрес')),
                ('notes', models.TextField(blank=True, null=True, verbose_name='Примечания')),
                ('active', models.BooleanField(default=True, verbose_name='Активен')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
            ],
            options={
                'verbose_name': 'Поставщик',
                'verbose_name_plural': 'Поставщики',
                'db_table': 'suppliers',
                'ordering': ['name'],
            },
        ),
        migrations.AddIndex(
            model_name='supplier',
            index=models.Index(fields=['name'], name='suppliers_name_idx'),
        ),
        migrations.AddIndex(
            model_name='supplier',
            index=models.Index(fields=['active'], name='suppliers_active_idx'),
        ),
        
        # Обновляем модель Ingredient
        # Сначала изменяем unit на выбор из списка
        migrations.AlterField(
            model_name='ingredient',
            name='unit',
            field=models.CharField(
                choices=[
                    ('кг', 'Килограмм (кг)'),
                    ('г', 'Грамм (г)'),
                    ('л', 'Литр (л)'),
                    ('мл', 'Миллилитр (мл)'),
                    ('шт', 'Штука (шт)'),
                    ('уп', 'Упаковка (уп)'),
                    ('банка', 'Банка'),
                    ('бутылка', 'Бутылка'),
                ],
                default='шт',
                help_text='Единица измерения продукта',
                max_length=50,
                verbose_name='Единица измерения'
            ),
        ),
        
        # Добавляем новые поля
        migrations.AddField(
            model_name='ingredient',
            name='price',
            field=models.DecimalField(
                blank=True,
                decimal_places=2,
                help_text='Цена за единицу измерения',
                max_digits=10,
                null=True,
                validators=[django.core.validators.MinValueValidator(0)],
                verbose_name='Цена'
            ),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='quantity',
            field=models.DecimalField(
                decimal_places=3,
                default=1,
                help_text='Количество в указанной единице измерения',
                max_digits=10,
                validators=[django.core.validators.MinValueValidator(0)],
                verbose_name='Количество'
            ),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='weight',
            field=models.DecimalField(
                blank=True,
                decimal_places=3,
                help_text='Вес одной единицы в килограммах (для поштучных товаров)',
                max_digits=10,
                null=True,
                validators=[django.core.validators.MinValueValidator(0)],
                verbose_name='Вес (кг)'
            ),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='supplier',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='ingredients',
                to='core.supplier',
                verbose_name='Поставщик'
            ),
        ),
        
        # Добавляем индекс для supplier
        migrations.AddIndex(
            model_name='ingredient',
            index=models.Index(fields=['supplier'], name='ingredients_supplier_idx'),
        ),
    ]

