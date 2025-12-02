# Generated manually on 2025-12-01
# Merge migration to resolve remaining conflicts between legacy server migrations
# (0018_remove_ttk_comments, 0045_add_telegram_admin_bot) and the latest local branch.

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0018_remove_ttk_comments'),
        ('core', '0050_merge_server_and_banned'),
    ]

    operations = [
        # Empty merge migration
    ]

