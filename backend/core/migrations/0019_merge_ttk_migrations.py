# Generated manually to merge conflicting migrations
# This migration was created to resolve conflicts between server and code migrations
# On server there was 0018_ttkcomment_ttkversionhistory, but in code we have 0019_remove_ttk_comments
# Since 0018_ttkcomment_ttkversionhistory doesn't exist in code, we only depend on 0019_remove_ttk_comments

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0019_remove_ttk_comments'),
    ]

    operations = [
        # Empty merge migration - resolves migration graph conflicts
        # This allows the migration graph to be consistent in CI/CD
    ]
