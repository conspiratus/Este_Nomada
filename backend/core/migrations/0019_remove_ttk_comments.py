# Generated manually to remove TTKComment model

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0018_ttkcomment_ttkversionhistory'),
    ]

    operations = [
        migrations.RunSQL(
            "DROP TABLE IF EXISTS ttk_comments;",
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]

