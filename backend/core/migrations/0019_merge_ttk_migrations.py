# Generated manually to merge conflicting migrations
# This migration merges 0018_ttkcomment_ttkversionhistory (on server) 
# with 0019_remove_ttk_comments (in code)

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0019_remove_ttk_comments'),  # From code
        ('core', '0018_ttkcomment_ttkversionhistory'),  # From server (if exists)
    ]

    operations = [
        # Empty merge migration - both branches are compatible
        # 0019_remove_ttk_comments just drops ttk_comments table
        # 0018_ttkcomment_ttkversionhistory creates tables that were later removed
        # So we can safely merge them
    ]
