# Generated manually to merge 0018_ttkcomment_ttkversionhistory (on server) 
# with 0021_alter_ttkversionhistory_ttk_and_more (in code)
# This resolves the conflict where both exist as leaf nodes on server
#
# Note: 0018_ttkcomment_ttkversionhistory exists only on server, not in code
# So this migration depends only on 0021, and on server we'll create
# a separate merge migration 0024 that merges 0018 and 0023

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0021_alter_ttkversionhistory_ttk_and_more'),
        # Note: 0018_ttkcomment_ttkversionhistory exists only on server
        # On server, we'll need to create 0024_merge_0018_and_0023 manually
    ]

    operations = [
        # Empty merge migration
        # This allows the migration graph to be consistent in CI/CD
    ]

