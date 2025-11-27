# Generated manually to safely delete TTKComment model
# This migration safely removes the ttk_comments table if it exists
# The table may have been already removed by 0019_remove_ttk_comments

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0023_merge_0018_and_0021'),
        # Note: 0024_merge_0018_and_0023 exists only on server
        # This migration will work on both server and local
    ]

    operations = [
        # Safely delete the table if it exists
        # This handles the case where the table was already deleted
        migrations.RunSQL(
            "DROP TABLE IF EXISTS ttk_comments;",
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]

