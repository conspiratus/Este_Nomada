# Generated manually to fix CI migration check

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0020_dishttk_multiple_support'),
    ]

    operations = [
        # Alter field ttk to ensure proper ForeignKey configuration
        migrations.AlterField(
            model_name='ttkversionhistory',
            name='ttk',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='version_history',
                to='core.dishttk',
                verbose_name='ТТК',
                help_text='ТТК, к которой относится версия'
            ),
        ),
        # Add index for better query performance
        migrations.AddIndex(
            model_name='ttkversionhistory',
            index=models.Index(fields=['ttk', '-created_at'], name='ttk_version_ttk_id_176576_idx'),
        ),
    ]

