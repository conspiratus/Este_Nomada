# Generated manually on 2025-11-30

from django.db import migrations, models
import django.db.models.deletion
from django.utils.text import slugify


def create_initial_price_sources(apps, schema_editor):
    """Создает начальные источники цен."""
    db_alias = schema_editor.connection.alias
    PriceSource = apps.get_model('core', 'PriceSource')

    sources_data = [
        {
            'name': 'Carrefour',
            'description': 'Сеть супермаркетов Carrefour',
            'file_format': 'csv',
            'active': True,
        },
        {
            'name': 'Alcampo',
            'description': 'Сеть супермаркетов Alcampo',
            'file_format': 'csv',
            'active': True,
        },
        {
            'name': 'Makro Cash & Carry',
            'description': 'Оптовый магазин Makro Cash & Carry',
            'file_format': 'excel',
            'active': True,
        },
    ]

    for source_data in sources_data:
        source, created = PriceSource.objects.using(db_alias).get_or_create(
            name=source_data['name'],
            defaults={
                'slug': slugify(source_data['name']),
                'description': source_data.get('description', ''),
                'file_format': source_data.get('file_format', 'csv'),
                'active': source_data.get('active', True),
            }
        )
        if created:
            print(f"Created price source: {source.name}")


def reverse_migration(apps, schema_editor):
    """Откат миграции."""
    db_alias = schema_editor.connection.alias
    PriceSource = apps.get_model('core', 'PriceSource')
    Ingredient = apps.get_model('core', 'Ingredient')

    # Удаляем привязки
    Ingredient.objects.using(db_alias).update(price_source=None, price_updated_at=None)
    
    # Удаляем источники
    PriceSource.objects.using(db_alias).all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0043_add_ingredient_categories'),
    ]

    operations = [
        # Создаем модель PriceSource
        migrations.CreateModel(
            name='PriceSource',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, unique=True, verbose_name='Название источника')),
                ('slug', models.SlugField(blank=True, max_length=255, unique=True, verbose_name='URL-адрес')),
                ('description', models.TextField(blank=True, null=True, verbose_name='Описание')),
                ('api_url', models.URLField(blank=True, help_text='URL для получения данных через API', null=True, verbose_name='API URL')),
                ('api_key', models.CharField(blank=True, help_text='Ключ для доступа к API', max_length=255, null=True, verbose_name='API ключ')),
                ('file_format', models.CharField(
                    choices=[
                        ('csv', 'CSV'),
                        ('excel', 'Excel'),
                        ('xml', 'XML'),
                        ('json', 'JSON'),
                    ],
                    default='csv',
                    help_text='Формат файла для импорта',
                    max_length=50,
                    verbose_name='Формат файла'
                )),
                ('active', models.BooleanField(default=True, verbose_name='Активен')),
                ('last_sync', models.DateTimeField(blank=True, null=True, verbose_name='Последняя синхронизация')),
                ('sync_frequency', models.IntegerField(
                    default=24,
                    help_text='Как часто обновлять цены (в часах)',
                    verbose_name='Частота синхронизации (часы)'
                )),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
            ],
            options={
                'verbose_name': 'Источник цен',
                'verbose_name_plural': 'Источники цен',
                'db_table': 'price_sources',
                'ordering': ['name'],
            },
        ),
        migrations.AddIndex(
            model_name='pricesource',
            index=models.Index(fields=['name'], name='price_sourc_name_idx'),
        ),
        migrations.AddIndex(
            model_name='pricesource',
            index=models.Index(fields=['slug'], name='price_sourc_slug_idx'),
        ),
        migrations.AddIndex(
            model_name='pricesource',
            index=models.Index(fields=['active'], name='price_sourc_active_idx'),
        ),
        
        # Добавляем поля в Ingredient
        migrations.AddField(
            model_name='ingredient',
            name='price_source',
            field=models.ForeignKey(
                blank=True,
                help_text='Откуда была получена цена',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='ingredients',
                to='core.pricesource',
                verbose_name='Источник цены'
            ),
        ),
        migrations.AddField(
            model_name='ingredient',
            name='price_updated_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Дата обновления цены'),
        ),
        
        # Добавляем индекс для price_source
        migrations.AddIndex(
            model_name='ingredient',
            index=models.Index(fields=['price_source'], name='ingredients_price_s_idx'),
        ),
        
        # Создаем начальные источники цен
        migrations.RunPython(
            create_initial_price_sources,
            reverse_migration,
        ),
    ]

