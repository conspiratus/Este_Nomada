# Generated manually on 2025-11-30
# Merge migration to resolve conflicts between:
# - 0018_remove_ttk_comments (exists on server)
# - 0045_add_telegram_admin_bot (old version on server, renamed to 0046 in code)
# - 0046_add_telegram_admin_bot (current version in code)

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0044_add_price_source'),
        ('core', '0045_rename_hero_button_active_order_idx_hero_button_active_e451a7_idx_and_more'),
        # Note: 0018_remove_ttk_comments and 0045_add_telegram_admin_bot exist only on server
        # This merge migration ensures compatibility
    ]

    operations = [
        # Empty merge migration - resolves migration graph conflicts
        # This allows the migration graph to be consistent
    ]

