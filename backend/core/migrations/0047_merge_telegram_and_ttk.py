# Generated manually on 2025-11-30
# Merge migration to resolve conflicts between:
# - 0018_remove_ttk_comments (exists on server, depends on 0017)
# - 0045_add_telegram_admin_bot (old version on server, depends on 0044)
# - 0046_add_telegram_admin_bot (current version in code)
#
# This merge depends on the latest common ancestor of all branches:
# - 0044_add_price_source (for telegram bot branch)
# - 0026_merge_0024_and_0025 (latest merge, which should include 0018 path)

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0044_add_price_source'),
        ('core', '0045_rename_hero_button_active_order_idx_hero_button_active_e451a7_idx_and_more'),
        # Note: On server, 0018_remove_ttk_comments and 0045_add_telegram_admin_bot also exist
        # This merge migration ensures compatibility by depending on the latest common migrations
    ]

    operations = [
        # Empty merge migration - resolves migration graph conflicts
        # This allows the migration graph to be consistent
    ]

