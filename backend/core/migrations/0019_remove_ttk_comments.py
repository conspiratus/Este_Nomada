# Generated manually to remove TTKComment model

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0017_dishttk'),
    ]

    operations = [
        migrations.RunSQL(
            "DROP TABLE IF EXISTS ttk_comments;",
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]

