# Generated manually to merge 0024_merge_0018_and_0023 (on server) with 0025_delete_ttkcomment
# This resolves the case where 0025 depends on 0024 on server but on 0023 in code

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0025_delete_ttkcomment'),
        # Note: 0024_merge_0018_and_0023 exists only on server
        # On server, 0025 depends on 0024, but in code it depends on 0023
        # This merge migration ensures compatibility
    ]

    operations = [
        # Empty merge migration
    ]

