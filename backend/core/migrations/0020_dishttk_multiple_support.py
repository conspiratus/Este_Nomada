# Generated manually for multiple TTK support

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0018_remove_ttk_comments'),
    ]

    operations = [
        # Добавляем поле name (сначала без default, потом заполним)
        migrations.AddField(
            model_name='dishttk',
            name='name',
            field=models.CharField(
                max_length=200,
                null=True,
                verbose_name='Название ТТК',
                help_text='Название или тип ТТК (например: "для дома", "для ресторана", "базовая версия")'
            ),
        ),
        # Добавляем поле git_path
        migrations.AddField(
            model_name='dishttk',
            name='git_path',
            field=models.CharField(
                blank=True,
                max_length=500,
                null=True,
                verbose_name='Путь в Git репозитории',
                help_text='Относительный путь к файлу ТТК в Git репозитории'
            ),
        ),
        # Заполняем name для существующих записей
        migrations.RunPython(
            lambda apps, schema_editor: apps.get_model('core', 'DishTTK').objects.update(name='Основная версия'),
            reverse_code=migrations.RunPython.noop,
        ),
        # Теперь делаем name обязательным с default
        migrations.AlterField(
            model_name='dishttk',
            name='name',
            field=models.CharField(
                default='Основная версия',
                max_length=200,
                verbose_name='Название ТТК',
                help_text='Название или тип ТТК (например: "для дома", "для ресторана", "базовая версия")'
            ),
        ),
        # Обновляем help_text для active
        migrations.AlterField(
            model_name='dishttk',
            name='active',
            field=models.BooleanField(
                default=True,
                verbose_name='Активна',
                help_text='Активна ли данная версия ТТК (только одна ТТК может быть активной для блюда)'
            ),
        ),
        # Обновляем ttk_file (делаем nullable)
        migrations.AlterField(
            model_name='dishttk',
            name='ttk_file',
            field=models.FileField(
                blank=True,
                help_text='Загрузите файл технико-технологической карты в формате Markdown (.md)',
                null=True,
                upload_to='ttk/',
                verbose_name='Файл ТТК (.md)'
            ),
        ),
        # Изменяем OneToOneField на ForeignKey
        # Используем RunSQL для изменения ограничения уникальности в БД
        migrations.RunSQL(
            # Удаляем уникальное ограничение для menu_item_id
            sql="ALTER TABLE dish_ttk DROP INDEX IF EXISTS dish_ttk_menu_item_id_unique;",
            reverse_sql=migrations.RunSQL.noop,
        ),
        # Теперь изменяем поле через AlterField
        migrations.AlterField(
            model_name='dishttk',
            name='menu_item',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='ttks',
                to='core.menuitem',
                verbose_name='Блюдо',
                help_text='Выберите блюдо, для которого создается ТТК'
            ),
        ),
        # Создаем модель TTKVersionHistory
        migrations.CreateModel(
            name='TTKVersionHistory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('version', models.CharField(help_text='Номер или название версии', max_length=50, verbose_name='Версия')),
                ('content', models.TextField(help_text='Содержимое файла ТТК на момент создания версии', verbose_name='Содержимое ТТК')),
                ('change_description', models.TextField(blank=True, help_text='Описание того, что было изменено в этой версии', null=True, verbose_name='Описание изменений')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания версии')),
                ('changed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='ttk_versions', to='auth.user', verbose_name='Изменено пользователем')),
                ('ttk', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='version_history', to='core.dishttk', verbose_name='ТТК')),
            ],
            options={
                'verbose_name': 'История версий ТТК',
                'verbose_name_plural': 'История версий ТТК',
                'db_table': 'ttk_version_history',
                'ordering': ['-created_at'],
            },
        ),
    ]

