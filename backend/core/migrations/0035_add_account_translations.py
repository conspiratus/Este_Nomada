# Generated manually on 2025-01-XX

from django.db import migrations


def add_account_translations(apps, schema_editor):
    """Добавляем недостающие переводы для account namespace на три языка (ru, es, en)."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Переводы для добавления
    translations = [
        # Русский (ru)
        ('ru', 'account', 'login', 'Войти'),
        ('ru', 'account', 'register', 'Регистрация'),
        ('ru', 'account', 'loginMessage', 'Войдите в свой аккаунт'),
        ('ru', 'account', 'emailPlaceholder', 'your@email.com'),
        ('ru', 'account', 'password', 'Пароль'),
        ('ru', 'account', 'passwordPlaceholder', 'Введите пароль'),
        ('ru', 'account', 'noAccount', 'Нет аккаунта?'),
        
        # Испанский (es)
        ('es', 'account', 'login', 'Iniciar Sesión'),
        ('es', 'account', 'register', 'Registrarse'),
        ('es', 'account', 'loginMessage', 'Inicia sesión en tu cuenta'),
        ('es', 'account', 'emailPlaceholder', 'tu@email.com'),
        ('es', 'account', 'password', 'Contraseña'),
        ('es', 'account', 'passwordPlaceholder', 'Ingresa tu contraseña'),
        ('es', 'account', 'noAccount', '¿No tienes una cuenta?'),
        
        # Английский (en)
        ('en', 'account', 'login', 'Log In'),
        ('en', 'account', 'register', 'Register'),
        ('en', 'account', 'loginMessage', 'Log in to your account'),
        ('en', 'account', 'emailPlaceholder', 'your@email.com'),
        ('en', 'account', 'password', 'Password'),
        ('en', 'account', 'passwordPlaceholder', 'Enter your password'),
        ('en', 'account', 'noAccount', "Don't have an account?"),
    ]
    
    created_count = 0
    for locale, namespace, key, value in translations:
        # Используем get_or_create, чтобы не создавать дубликаты
        translation, created = Translation.objects.using(db_alias).get_or_create(
            locale=locale,
            namespace=namespace,
            key=key,
            defaults={'value': value}
        )
        if created:
            created_count += 1
        else:
            # Если перевод уже существует, обновляем его значение
            translation.value = value
            translation.save(using=db_alias)
    
    print(f'[Migration] Created/updated {created_count} account translations')


def reverse_migration(apps, schema_editor):
    """Откат миграции - удаляем созданные переводы."""
    db_alias = schema_editor.connection.alias
    Translation = apps.get_model('core', 'Translation')
    
    # Ключи для удаления
    keys_to_remove = [
        'login', 'register', 'loginMessage', 'emailPlaceholder',
        'password', 'passwordPlaceholder', 'noAccount'
    ]
    
    locales = ['ru', 'es', 'en']
    
    for locale in locales:
        for key in keys_to_remove:
            Translation.objects.using(db_alias).filter(
                locale=locale,
                namespace='account',
                key=key
            ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0034_herobutton_herobuttontranslation'),
    ]

    operations = [
        migrations.RunPython(add_account_translations, reverse_migration),
    ]

