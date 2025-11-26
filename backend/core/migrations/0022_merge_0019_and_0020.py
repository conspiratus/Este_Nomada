# Generated manually to merge 0019_merge_ttk_migrations and 0020_dishttk_multiple_support
# This resolves the conflict on server where both exist as leaf nodes

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0019_merge_ttk_migrations'),
        ('core', '0020_dishttk_multiple_support'),
    ]

    operations = [
        # Empty merge migration
    ]

