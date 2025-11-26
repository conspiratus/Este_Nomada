# Generated manually to merge 0018_ttkcomment_ttkversionhistory (on server) 
# with 0021_alter_ttkversionhistory_ttk_and_more (in code)
# This resolves the conflict where both exist as leaf nodes on server

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0021_alter_ttkversionhistory_ttk_and_more'),
        ('core', '0018_ttkcomment_ttkversionhistory'),  # Exists only on server
    ]

    operations = [
        # Empty merge migration
        # Both migrations work with TTKVersionHistory model
        # 0018 creates it, 0021 modifies it
    ]

