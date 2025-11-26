#!/usr/bin/env python
"""
Скрипт для исправления экранированного HTML в секциях футера.
Декодирует HTML сущности в полях title и content.
"""
import os
import sys
import django

# Настройка Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')
django.setup()

from core.models import FooterSection, FooterSectionTranslation
import html


def fix_html_entities(text):
    """Декодирует HTML сущности."""
    if not text:
        return text
    
    # Декодируем HTML сущности
    decoded = html.unescape(text)
    
    # Если всё ещё есть экранированные символы, декодируем ещё раз
    if decoded != html.unescape(decoded):
        decoded = html.unescape(decoded)
    
    return decoded


def fix_footer_sections():
    """Исправляет экранированный HTML во всех секциях футера."""
    print("🔍 Проверяю секции футера...")
    
    sections = FooterSection.objects.all()
    fixed_count = 0
    
    for section in sections:
        original_title = section.title
        original_content = section.content
        
        fixed_title = fix_html_entities(original_title)
        fixed_content = fix_html_entities(original_content)
        
        if fixed_title != original_title or fixed_content != original_content:
            print(f"\n📝 Секция ID {section.id} ({section.position}):")
            print(f"   Title до:  {original_title[:80]}...")
            print(f"   Title после: {fixed_title[:80]}...")
            
            section.title = fixed_title
            section.content = fixed_content
            section.save()
            fixed_count += 1
        
        # Исправляем переводы
        for translation in section.translations.all():
            original_title = translation.title
            original_content = translation.content
            
            fixed_title = fix_html_entities(original_title)
            fixed_content = fix_html_entities(original_content)
            
            if fixed_title != original_title or fixed_content != original_content:
                print(f"\n📝 Перевод ID {translation.id} ({translation.locale}):")
                print(f"   Title до:  {original_title[:80]}...")
                print(f"   Title после: {fixed_title[:80]}...")
                
                translation.title = fixed_title
                translation.content = fixed_content
                translation.save()
                fixed_count += 1
    
    print(f"\n✅ Исправлено секций: {fixed_count}")
    print("✅ Готово!")


if __name__ == '__main__':
    fix_footer_sections()


