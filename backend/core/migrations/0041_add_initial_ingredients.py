# Generated manually on 2025-11-29

from django.db import migrations


def add_initial_ingredients(apps, schema_editor):
    """Добавляем первичный список ингредиентов на основе ТТК."""
    db_alias = schema_editor.connection.alias
    Ingredient = apps.get_model('core', 'Ingredient')

    # Список ингредиентов на основе ТТК и типичных продуктов для ресторана
    ingredients_data = [
        # Мучные продукты
        {'name': 'Мука пшеничная', 'unit': 'кг', 'description': 'Пшеничная мука высшего сорта'},
        
        # Специи и приправы
        {'name': 'Соль', 'unit': 'кг', 'description': 'Поваренная соль'},
        {'name': 'Перец черный молотый', 'unit': 'г', 'description': 'Черный перец молотый'},
        {'name': 'Перец красный острый', 'unit': 'г', 'description': 'Красный перец острый молотый'},
        {'name': 'Кориандр молотый', 'unit': 'г', 'description': 'Кориандр молотый'},
        {'name': 'Зира (кумин)', 'unit': 'г', 'description': 'Зира (кумин) молотая'},
        {'name': 'Куркума', 'unit': 'г', 'description': 'Куркума молотая'},
        {'name': 'Паприка', 'unit': 'г', 'description': 'Паприка молотая'},
        {'name': 'Корица', 'unit': 'г', 'description': 'Корица молотая'},
        {'name': 'Гвоздика', 'unit': 'г', 'description': 'Гвоздика молотая'},
        {'name': 'Лавровый лист', 'unit': 'г', 'description': 'Лавровый лист сушеный'},
        
        # Мясо
        {'name': 'Говядина (лопатка)', 'unit': 'кг', 'description': 'Говядина лопатка'},
        {'name': 'Говядина (пашина)', 'unit': 'кг', 'description': 'Говядина пашина'},
        {'name': 'Свинина (шея)', 'unit': 'кг', 'description': 'Свинина шея'},
        {'name': 'Свинина (подчеревок)', 'unit': 'кг', 'description': 'Свинина подчеревок'},
        {'name': 'Баранина (голяшки)', 'unit': 'кг', 'description': 'Баранина голяшки'},
        {'name': 'Баранина (мякоть)', 'unit': 'кг', 'description': 'Баранина мякоть'},
        
        # Овощи
        {'name': 'Лук репчатый', 'unit': 'кг', 'description': 'Лук репчатый'},
        {'name': 'Морковь', 'unit': 'кг', 'description': 'Морковь красная'},
        {'name': 'Чеснок', 'unit': 'кг', 'description': 'Чеснок'},
        {'name': 'Помидоры', 'unit': 'кг', 'description': 'Помидоры свежие'},
        {'name': 'Перец болгарский', 'unit': 'кг', 'description': 'Перец болгарский'},
        {'name': 'Баклажаны', 'unit': 'кг', 'description': 'Баклажаны'},
        {'name': 'Кабачки', 'unit': 'кг', 'description': 'Кабачки'},
        {'name': 'Картофель', 'unit': 'кг', 'description': 'Картофель'},
        
        # Крупы и бобовые
        {'name': 'Рис испанский (Bomba)', 'unit': 'кг', 'description': 'Рис испанский сорт Bomba'},
        {'name': 'Рис испанский (Bahía)', 'unit': 'кг', 'description': 'Рис испанский сорт Bahía'},
        {'name': 'Рис длиннозерный', 'unit': 'кг', 'description': 'Рис длиннозерный'},
        {'name': 'Фасоль красная', 'unit': 'кг', 'description': 'Фасоль красная'},
        {'name': 'Фасоль белая', 'unit': 'кг', 'description': 'Фасоль белая'},
        {'name': 'Чечевица', 'unit': 'кг', 'description': 'Чечевица'},
        {'name': 'Горох', 'unit': 'кг', 'description': 'Горох сушеный'},
        
        # Масла и жиры
        {'name': 'Масло топленое (гхи)', 'unit': 'кг', 'description': 'Масло топленое (гхи)'},
        {'name': 'Масло подсолнечное', 'unit': 'л', 'description': 'Масло подсолнечное рафинированное'},
        {'name': 'Масло оливковое', 'unit': 'л', 'description': 'Масло оливковое extra virgin'},
        {'name': 'Масло сливочное', 'unit': 'кг', 'description': 'Масло сливочное'},
        
        # Молочные продукты
        {'name': 'Молоко', 'unit': 'л', 'description': 'Молоко цельное'},
        {'name': 'Сметана', 'unit': 'кг', 'description': 'Сметана'},
        {'name': 'Творог', 'unit': 'кг', 'description': 'Творог'},
        {'name': 'Сыр твердый', 'unit': 'кг', 'description': 'Сыр твердый'},
        {'name': 'Сыр фета', 'unit': 'кг', 'description': 'Сыр фета'},
        
        # Зелень
        {'name': 'Укроп', 'unit': 'г', 'description': 'Укроп свежий'},
        {'name': 'Петрушка', 'unit': 'г', 'description': 'Петрушка свежая'},
        {'name': 'Кинза (кориандр)', 'unit': 'г', 'description': 'Кинза (кориандр) свежая'},
        {'name': 'Базилик', 'unit': 'г', 'description': 'Базилик свежий'},
        {'name': 'Мята', 'unit': 'г', 'description': 'Мята свежая'},
        {'name': 'Зеленый лук', 'unit': 'г', 'description': 'Зеленый лук'},
        
        # Фрукты
        {'name': 'Яблоки', 'unit': 'кг', 'description': 'Яблоки'},
        {'name': 'Груши', 'unit': 'кг', 'description': 'Груши'},
        {'name': 'Айва', 'unit': 'кг', 'description': 'Айва'},
        {'name': 'Гранат', 'unit': 'кг', 'description': 'Гранат'},
        
        # Консервы
        {'name': 'Томатная паста', 'unit': 'кг', 'description': 'Томатная паста'},
        {'name': 'Помидоры консервированные', 'unit': 'кг', 'description': 'Помидоры консервированные'},
        
        # Жидкости
        {'name': 'Вода', 'unit': 'л', 'description': 'Вода питьевая'},
        {'name': 'Бульон мясной', 'unit': 'л', 'description': 'Бульон мясной'},
        {'name': 'Бульон куриный', 'unit': 'л', 'description': 'Бульон куриный'},
        {'name': 'Вино белое', 'unit': 'л', 'description': 'Вино белое сухое'},
        {'name': 'Вино красное', 'unit': 'л', 'description': 'Вино красное сухое'},
        {'name': 'Уксус винный', 'unit': 'мл', 'description': 'Уксус винный'},
        {'name': 'Уксус бальзамический', 'unit': 'мл', 'description': 'Уксус бальзамический'},
        
        # Орехи и семена
        {'name': 'Грецкие орехи', 'unit': 'кг', 'description': 'Грецкие орехи очищенные'},
        {'name': 'Миндаль', 'unit': 'кг', 'description': 'Миндаль очищенный'},
        {'name': 'Кедровые орехи', 'unit': 'г', 'description': 'Кедровые орехи'},
        {'name': 'Кунжут', 'unit': 'г', 'description': 'Кунжут'},
        
        # Другое
        {'name': 'Яйца куриные', 'unit': 'шт', 'description': 'Яйца куриные категории С0'},
        {'name': 'Лимон', 'unit': 'шт', 'description': 'Лимон'},
        {'name': 'Лайм', 'unit': 'шт', 'description': 'Лайм'},
    ]

    created_count = 0
    for ingredient_data in ingredients_data:
        # Используем get_or_create, чтобы не создавать дубликаты
        ingredient, created = Ingredient.objects.using(db_alias).get_or_create(
            name=ingredient_data['name'],
            unit=ingredient_data['unit'],
            defaults={
                'description': ingredient_data.get('description', ''),
            }
        )
        if created:
            created_count += 1

    print(f'[Migration] Created {created_count} initial ingredients')


def reverse_migration(apps, schema_editor):
    """Откат миграции - удаляем созданные ингредиенты."""
    db_alias = schema_editor.connection.alias
    Ingredient = apps.get_model('core', 'Ingredient')

    # Удаляем только те ингредиенты, которые были созданы этой миграцией
    # (те, у которых нет цены и поставщика - т.е. базовые)
    Ingredient.objects.using(db_alias).filter(
        price__isnull=True,
        supplier__isnull=True
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0040_add_supplier_and_ingredient_fields'),
    ]

    operations = [
        migrations.RunPython(add_initial_ingredients, reverse_migration),
    ]

