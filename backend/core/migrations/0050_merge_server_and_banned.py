# Generated manually on 2025-12-01
# Merge migration to resolve conflicts between server-only migrations
# (0018_remove_ttk_comments, 0045_add_telegram_admin_bot, 0046_add_telegram_admin_bot)
# and local migration 0049_add_banned_to_telegram_admin.
#
# This merge ensures that deployments via CI/CD won't require manual merges.

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0046_add_telegram_admin_bot'),
        ('core', '0049_add_banned_to_telegram_admin'),
    ]

    operations = [
        # Empty merge migration – this simply resolves the migration graph conflicts.
    ]

