# Generated manually to merge conflicting migrations
# This migration merges:
# - 0018_ttkcomment_ttkversionhistory (exists only on server)
# - 0018_remove_ttk_comments (old version on server, renamed to 0019 in code)
# - 0019_remove_ttk_comments (current version in code)
# 
# On server: both 0018_ttkcomment_ttkversionhistory and 0018_remove_ttk_comments exist
# In code: only 0019_remove_ttk_comments exists (renamed from 0018)

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0019_remove_ttk_comments'),  # Current version in code
        # Note: 0018_ttkcomment_ttkversionhistory and 0018_remove_ttk_comments 
        # exist only on server and will be handled there
    ]

    operations = [
        # Empty merge migration - resolves migration graph conflicts
        # This allows the migration graph to be consistent in CI/CD
    ]
