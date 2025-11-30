# Generated manually on 2025-11-29

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0041_add_initial_ingredients'),
    ]

    operations = [
        # Переименовываем Stock в "Готовая продукция"
        migrations.AlterModelOptions(
            name='stock',
            options={
                'verbose_name': 'Готовая продукция',
                'verbose_name_plural': 'Готовая продукция',
                'db_table': 'stock',
            },
        ),
        
        # Создаем модель IngredientStock
        migrations.CreateModel(
            name='IngredientStock',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('quantity', models.DecimalField(
                    decimal_places=3,
                    default=0,
                    help_text='Количество ингредиента на складе в единицах измерения продукта',
                    max_digits=10,
                    validators=[django.core.validators.MinValueValidator(0)],
                    verbose_name='Количество на складе'
                )),
                ('location', models.CharField(
                    blank=True,
                    help_text='Место хранения на складе (например: холодильник, морозильник, полка)',
                    max_length=255,
                    null=True,
                    verbose_name='Место хранения'
                )),
                ('notes', models.TextField(
                    blank=True,
                    help_text='Дополнительные заметки о хранении',
                    null=True,
                    verbose_name='Примечания'
                )),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
                ('ingredient', models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='ingredient_stock',
                    to='core.ingredient',
                    verbose_name='Ингредиент'
                )),
            ],
            options={
                'verbose_name': 'Склад (ингредиенты)',
                'verbose_name_plural': 'Склад (ингредиенты)',
                'db_table': 'ingredient_stock',
            },
        ),
        migrations.AddIndex(
            model_name='ingredientstock',
            index=models.Index(fields=['ingredient'], name='ingredient_st_ingredi_idx'),
        ),
    ]

