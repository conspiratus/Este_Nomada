# Generated manually on 2025-11-29

from django.db import migrations, models
import django.db.models.deletion
from django.utils.text import slugify


def create_categories_and_assign_ingredients(apps, schema_editor):
    """Создает категории ингредиентов и привязывает существующие ингредиенты."""
    db_alias = schema_editor.connection.alias
    IngredientCategory = apps.get_model('core', 'IngredientCategory')
    Ingredient = apps.get_model('core', 'Ingredient')

    # Создаем категории
    categories_data = [
        {'name': 'Овощи', 'order': 1, 'description': 'Свежие овощи'},
        {'name': 'Мясо', 'order': 2, 'description': 'Мясные продукты'},
        {'name': 'Фрукты', 'order': 3, 'description': 'Свежие фрукты'},
        {'name': 'Зелень', 'order': 4, 'description': 'Свежая зелень и травы'},
        {'name': 'Крупы и бобовые', 'order': 5, 'description': 'Крупы, рис, бобовые'},
        {'name': 'Мучные продукты', 'order': 6, 'description': 'Мука, тесто'},
        {'name': 'Специи и приправы', 'order': 7, 'description': 'Специи, приправы, соль'},
        {'name': 'Масла и жиры', 'order': 8, 'description': 'Масла, жиры'},
        {'name': 'Молочные продукты', 'order': 9, 'description': 'Молоко, сыр, сметана'},
        {'name': 'Консервы', 'order': 10, 'description': 'Консервированные продукты'},
        {'name': 'Жидкости', 'order': 11, 'description': 'Вода, бульоны, вино, уксус'},
        {'name': 'Орехи и семена', 'order': 12, 'description': 'Орехи, семена'},
        {'name': 'Другое', 'order': 99, 'description': 'Прочие ингредиенты'},
    ]

    categories = {}
    for cat_data in categories_data:
        category, created = IngredientCategory.objects.using(db_alias).get_or_create(
            name=cat_data['name'],
            defaults={
                'slug': slugify(cat_data['name']),
                'order': cat_data['order'],
                'description': cat_data.get('description', ''),
                'active': True,
            }
        )
        categories[cat_data['name']] = category
        if created:
            print(f"Created category: {category.name}")

    # Привязываем существующие ингредиенты к категориям
    category_mapping = {
        # Овощи
        'Лук репчатый': 'Овощи',
        'Морковь': 'Овощи',
        'Чеснок': 'Овощи',
        'Помидоры': 'Овощи',
        'Перец болгарский': 'Овощи',
        'Баклажаны': 'Овощи',
        'Кабачки': 'Овощи',
        'Картофель': 'Овощи',
        
        # Мясо
        'Говядина (лопатка)': 'Мясо',
        'Говядина (пашина)': 'Мясо',
        'Свинина (шея)': 'Мясо',
        'Свинина (подчеревок)': 'Мясо',
        'Баранина (голяшки)': 'Мясо',
        'Баранина (мякоть)': 'Мясо',
        
        # Фрукты
        'Яблоки': 'Фрукты',
        'Груши': 'Фрукты',
        'Айва': 'Фрукты',
        'Гранат': 'Фрукты',
        'Лимон': 'Фрукты',
        'Лайм': 'Фрукты',
        
        # Зелень
        'Укроп': 'Зелень',
        'Петрушка': 'Зелень',
        'Кинза (кориандр)': 'Зелень',
        'Базилик': 'Зелень',
        'Мята': 'Зелень',
        'Зеленый лук': 'Зелень',
        
        # Крупы и бобовые
        'Рис испанский (Bomba)': 'Крупы и бобовые',
        'Рис испанский (Bahía)': 'Крупы и бобовые',
        'Рис длиннозерный': 'Крупы и бобовые',
        'Фасоль красная': 'Крупы и бобовые',
        'Фасоль белая': 'Крупы и бобовые',
        'Чечевица': 'Крупы и бобовые',
        'Горох': 'Крупы и бобовые',
        
        # Мучные продукты
        'Мука пшеничная': 'Мучные продукты',
        
        # Специи и приправы
        'Соль': 'Специи и приправы',
        'Перец черный молотый': 'Специи и приправы',
        'Перец красный острый': 'Специи и приправы',
        'Кориандр молотый': 'Специи и приправы',
        'Зира (кумин)': 'Специи и приправы',
        'Куркума': 'Специи и приправы',
        'Паприка': 'Специи и приправы',
        'Корица': 'Специи и приправы',
        'Гвоздика': 'Специи и приправы',
        'Лавровый лист': 'Специи и приправы',
        
        # Масла и жиры
        'Масло топленое (гхи)': 'Масла и жиры',
        'Масло подсолнечное': 'Масла и жиры',
        'Масло оливковое': 'Масла и жиры',
        'Масло сливочное': 'Масла и жиры',
        
        # Молочные продукты
        'Молоко': 'Молочные продукты',
        'Сметана': 'Молочные продукты',
        'Творог': 'Молочные продукты',
        'Сыр твердый': 'Молочные продукты',
        'Сыр фета': 'Молочные продукты',
        
        # Консервы
        'Томатная паста': 'Консервы',
        'Помидоры консервированные': 'Консервы',
        
        # Жидкости
        'Вода': 'Жидкости',
        'Бульон мясной': 'Жидкости',
        'Бульон куриный': 'Жидкости',
        'Вино белое': 'Жидкости',
        'Вино красное': 'Жидкости',
        'Уксус винный': 'Жидкости',
        'Уксус бальзамический': 'Жидкости',
        
        # Орехи и семена
        'Грецкие орехи': 'Орехи и семена',
        'Миндаль': 'Орехи и семена',
        'Кедровые орехи': 'Орехи и семена',
        'Кунжут': 'Орехи и семена',
        
        # Другое
        'Яйца куриные': 'Другое',
    }

    updated_count = 0
    for ingredient in Ingredient.objects.using(db_alias).all():
        if ingredient.name in category_mapping:
            category_name = category_mapping[ingredient.name]
            if category_name in categories:
                ingredient.category = categories[category_name]
                ingredient.save(using=db_alias)
                updated_count += 1

    print(f"Assigned categories to {updated_count} ingredients")


def reverse_migration(apps, schema_editor):
    """Откат миграции - удаляем категории."""
    db_alias = schema_editor.connection.alias
    IngredientCategory = apps.get_model('core', 'IngredientCategory')
    Ingredient = apps.get_model('core', 'Ingredient')

    # Удаляем привязки
    Ingredient.objects.using(db_alias).update(category=None)
    
    # Удаляем категории
    IngredientCategory.objects.using(db_alias).all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0042_rename_stock_and_add_ingredient_stock'),
    ]

    operations = [
        # Создаем модель IngredientCategory
        migrations.CreateModel(
            name='IngredientCategory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, unique=True, verbose_name='Название категории')),
                ('slug', models.SlugField(blank=True, max_length=255, unique=True, verbose_name='URL-адрес')),
                ('description', models.TextField(blank=True, null=True, verbose_name='Описание')),
                ('order', models.IntegerField(default=0, help_text='Чем меньше число, тем выше в списке', verbose_name='Порядок сортировки')),
                ('active', models.BooleanField(default=True, verbose_name='Активна')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Дата обновления')),
            ],
            options={
                'verbose_name': 'Категория ингредиентов',
                'verbose_name_plural': 'Категории ингредиентов',
                'db_table': 'ingredient_categories',
                'ordering': ['order', 'name'],
            },
        ),
        migrations.AddIndex(
            model_name='ingredientcategory',
            index=models.Index(fields=['name'], name='ingredient_c_name_idx'),
        ),
        migrations.AddIndex(
            model_name='ingredientcategory',
            index=models.Index(fields=['slug'], name='ingredient_c_slug_idx'),
        ),
        migrations.AddIndex(
            model_name='ingredientcategory',
            index=models.Index(fields=['active'], name='ingredient_c_active_idx'),
        ),
        
        # Добавляем поле category в Ingredient
        migrations.AddField(
            model_name='ingredient',
            name='category',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='ingredients',
                to='core.ingredientcategory',
                verbose_name='Категория'
            ),
        ),
        
        # Добавляем индекс для category
        migrations.AddIndex(
            model_name='ingredient',
            index=models.Index(fields=['category'], name='ingredients_category_idx'),
        ),
        
        # Создаем категории и привязываем ингредиенты
        migrations.RunPython(
            create_categories_and_assign_ingredients,
            reverse_migration,
        ),
    ]

