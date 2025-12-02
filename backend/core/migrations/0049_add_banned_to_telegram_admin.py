# Generated manually

from django.db import migrations, models


def add_banned_field(apps, schema_editor):
    """Добавить колонку banned и сделать user_id nullable, если нужно."""
    table_name = 'telegram_admin'
    connection = schema_editor.connection

    with connection.cursor() as cursor:
        # Проверяем, существует ли колонка banned
        cursor.execute(
            """
            SELECT COUNT(*)
            FROM information_schema.columns
            WHERE table_schema = DATABASE()
              AND table_name = %s
              AND column_name = 'banned'
            """,
            [table_name],
        )
        (exists_banned,) = cursor.fetchone()

        if not exists_banned:
            cursor.execute(
                """
                ALTER TABLE telegram_admin
                ADD COLUMN banned BOOLEAN NOT NULL DEFAULT FALSE
                COMMENT 'Если включено, бот не будет отправлять этому пользователю никакие сообщения'
                """
            )

        # Проверяем, nullable ли user_id
        cursor.execute(
            """
            SELECT IS_NULLABLE
            FROM information_schema.columns
            WHERE table_schema = DATABASE()
              AND table_name = %s
              AND column_name = 'user_id'
            """,
            [table_name],
        )
        result = cursor.fetchone()
        if result:
            (is_nullable,) = result
            if is_nullable != 'YES':
                cursor.execute(
                    """
                    ALTER TABLE telegram_admin
                    MODIFY COLUMN user_id INT NULL
                    """
                )


def noop(apps, schema_editor):
    """Обратное действие не требуется."""
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0048_add_orders_display_statuses'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_banned_field, noop),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='telegramadmin',
                    name='banned',
                    field=models.BooleanField(
                        default=False,
                        help_text='Если включено, бот не будет отправлять этому пользователю никакие сообщения',
                        verbose_name='Забанен'
                    ),
                ),
                migrations.AlterField(
                    model_name='telegramadmin',
                    name='user',
                    field=models.OneToOneField(
                        blank=True,
                        help_text='Связь с пользователем Django (опционально)',
                        null=True,
                        on_delete=models.SET_NULL,
                        related_name='telegram_admin',
                        to='auth.user',
                        verbose_name='Пользователь'
                    ),
                ),
            ],
        ),
    ]

