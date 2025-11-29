# Generated manually on 2025-01-XX

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0037_add_review_translations'),
    ]

    operations = [
        migrations.CreateModel(
            name='Ingredient',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, verbose_name='Название продукта')),
                ('unit', models.CharField(default='шт', help_text='Например: кг, г, л, мл, шт', max_length=50, verbose_name='Единица измерения')),
                ('description', models.TextField(blank=True, null=True, verbose_name='Описание')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
            ],
            options={
                'verbose_name': 'Ингредиент',
                'verbose_name_plural': 'Ингредиенты',
                'db_table': 'ingredients',
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='Stock',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('home_kitchen_quantity', models.IntegerField(default=0, help_text='Количество порций на домашней кухне', validators=[django.core.validators.MinValueValidator(0)], verbose_name='Остаток на домашней кухне')),
                ('delivery_kitchen_quantity', models.IntegerField(default=0, help_text='Количество порций на кухне доставки', validators=[django.core.validators.MinValueValidator(0)], verbose_name='Остаток на кухне доставки')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
                ('menu_item', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='stock', to='core.menuitem', verbose_name='Блюдо')),
            ],
            options={
                'verbose_name': 'Остаток на складе',
                'verbose_name_plural': 'Остатки на складе',
                'db_table': 'stock',
            },
        ),
        migrations.CreateModel(
            name='MenuItemIngredient',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('quantity', models.DecimalField(decimal_places=3, help_text='Количество ингредиента на одну порцию блюда', max_digits=10, validators=[django.core.validators.MinValueValidator(0)], verbose_name='Количество')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
                ('ingredient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='menu_items', to='core.ingredient', verbose_name='Ингредиент')),
                ('menu_item', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ingredients', to='core.menuitem', verbose_name='Блюдо')),
            ],
            options={
                'verbose_name': 'Ингредиент блюда',
                'verbose_name_plural': 'Ингредиенты блюд',
                'db_table': 'menu_item_ingredients',
                'unique_together': {('menu_item', 'ingredient')},
            },
        ),
        migrations.AddIndex(
            model_name='stock',
            index=models.Index(fields=['menu_item'], name='stock_menu_item_idx'),
        ),
        migrations.AddIndex(
            model_name='ingredient',
            index=models.Index(fields=['name'], name='ingredients_name_idx'),
        ),
        migrations.AddIndex(
            model_name='menuitemingredient',
            index=models.Index(fields=['menu_item'], name='menu_item_ing_menu_item_idx'),
        ),
        migrations.AddIndex(
            model_name='menuitemingredient',
            index=models.Index(fields=['ingredient'], name='menu_item_ing_ingredie_idx'),
        ),
    ]

