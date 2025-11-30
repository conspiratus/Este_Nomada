# Generated manually on 2025-01-XX
# Updated to safely handle existing tables

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


def create_tables_if_not_exists(apps, schema_editor):
    """Создает таблицы только если они не существуют."""
    db_alias = schema_editor.connection.alias
    with schema_editor.connection.cursor() as cursor:
        # Проверяем существование таблиц
        tables_to_check = ['ingredients', 'stock', 'menu_item_ingredients']
        existing_tables = []
        
        for table in tables_to_check:
            cursor.execute("""
                SELECT COUNT(*) 
                FROM information_schema.tables 
                WHERE table_schema = DATABASE() 
                AND table_name = %s
            """, [table])
            if cursor.fetchone()[0] > 0:
                existing_tables.append(table)
                print(f"Table '{table}' already exists, will skip creation")
        
        return existing_tables


def reverse_create_tables(apps, schema_editor):
    """Откат миграции."""
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0037_add_review_translations'),
    ]

    operations = [
        # Проверяем существование таблиц перед созданием
        migrations.RunPython(
            create_tables_if_not_exists,
            reverse_create_tables,
        ),
        # Используем SeparateDatabaseAndState для безопасного создания моделей
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Для MySQL создаем таблицы только если их нет
                migrations.RunSQL(
                    sql="""
                        SET @exist := (SELECT COUNT(*) FROM information_schema.tables 
                                       WHERE table_schema = DATABASE() AND table_name = 'ingredients');
                        SET @sqlstmt := IF(@exist = 0, 
                            'CREATE TABLE ingredients (
                                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                name VARCHAR(255) NOT NULL,
                                unit VARCHAR(50) NOT NULL DEFAULT ''шт'',
                                description LONGTEXT,
                                created_at DATETIME(6) NOT NULL,
                                updated_at DATETIME(6) NOT NULL
                            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
                            'SELECT ''Table ingredients already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                    """,
                    reverse_sql="DROP TABLE IF EXISTS ingredients;",
                ),
                migrations.RunSQL(
                    sql="""
                        SET @exist := (SELECT COUNT(*) FROM information_schema.tables 
                                       WHERE table_schema = DATABASE() AND table_name = 'stock');
                        SET @sqlstmt := IF(@exist = 0, 
                            'CREATE TABLE stock (
                                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                home_kitchen_quantity INT NOT NULL DEFAULT 0,
                                delivery_kitchen_quantity INT NOT NULL DEFAULT 0,
                                created_at DATETIME(6) NOT NULL,
                                updated_at DATETIME(6) NOT NULL,
                                menu_item_id BIGINT NOT NULL UNIQUE,
                                CONSTRAINT stock_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE
                            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
                            'SELECT ''Table stock already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                    """,
                    reverse_sql="DROP TABLE IF EXISTS stock;",
                ),
                migrations.RunSQL(
                    sql="""
                        SET @exist := (SELECT COUNT(*) FROM information_schema.tables 
                                       WHERE table_schema = DATABASE() AND table_name = 'menu_item_ingredients');
                        SET @sqlstmt := IF(@exist = 0, 
                            'CREATE TABLE menu_item_ingredients (
                                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                quantity DECIMAL(10, 3) NOT NULL,
                                created_at DATETIME(6) NOT NULL,
                                updated_at DATETIME(6) NOT NULL,
                                ingredient_id BIGINT NOT NULL,
                                menu_item_id BIGINT NOT NULL,
                                CONSTRAINT menu_item_ingredients_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
                                CONSTRAINT menu_item_ingredients_menu_item_id_fk FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE,
                                UNIQUE KEY menu_item_ingredients_unique (menu_item_id, ingredient_id)
                            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
                            'SELECT ''Table menu_item_ingredients already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                    """,
                    reverse_sql="DROP TABLE IF EXISTS menu_item_ingredients;",
                ),
                # Создаем индексы только если их нет
                migrations.RunSQL(
                    sql="""
                        SET @exist := (SELECT COUNT(*) FROM information_schema.statistics 
                                       WHERE table_schema = DATABASE() AND table_name = 'stock' AND index_name = 'stock_menu_item_idx');
                        SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX stock_menu_item_idx ON stock(menu_item_id)', 'SELECT ''Index already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                        
                        SET @exist := (SELECT COUNT(*) FROM information_schema.statistics 
                                       WHERE table_schema = DATABASE() AND table_name = 'ingredients' AND index_name = 'ingredients_name_idx');
                        SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX ingredients_name_idx ON ingredients(name)', 'SELECT ''Index already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                        
                        SET @exist := (SELECT COUNT(*) FROM information_schema.statistics 
                                       WHERE table_schema = DATABASE() AND table_name = 'menu_item_ingredients' AND index_name = 'menu_item_ing_menu_item_idx');
                        SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX menu_item_ing_menu_item_idx ON menu_item_ingredients(menu_item_id)', 'SELECT ''Index already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                        
                        SET @exist := (SELECT COUNT(*) FROM information_schema.statistics 
                                       WHERE table_schema = DATABASE() AND table_name = 'menu_item_ingredients' AND index_name = 'menu_item_ing_ingredie_idx');
                        SET @sqlstmt := IF(@exist = 0, 'CREATE INDEX menu_item_ing_ingredie_idx ON menu_item_ingredients(ingredient_id)', 'SELECT ''Index already exists''');
                        PREPARE stmt FROM @sqlstmt;
                        EXECUTE stmt;
                        DEALLOCATE PREPARE stmt;
                    """,
                    reverse_sql=migrations.RunSQL.noop,
                ),
            ],
            state_operations=[
                # Обновляем состояние Django, чтобы оно знало о моделях
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
            ],
        ),
    ]

