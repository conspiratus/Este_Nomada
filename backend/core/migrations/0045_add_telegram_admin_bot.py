# Generated manually on 2025-12-01
# Placeholder migration to match server history where a migration with this
# name already exists. It does not perform any operations locally because
# the actual database changes are handled by 0046_add_telegram_admin_bot,
# but having this migration keeps the migration graph consistent with prod.

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0044_add_price_source'),
    ]

    operations = [
        # No database/state changes. This migration exists purely to satisfy
        # the migration graph (server already has a migration with this name).
    ]

