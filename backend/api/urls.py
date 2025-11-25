"""
API URLs.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    StoryViewSet, MenuItemViewSet, SettingsViewSet, OrderViewSet,
    InstagramPostViewSet, TranslationViewSet,
    HeroImageViewSet, HeroSettingsViewSet, ContentSectionViewSet, AboutSectionViewSet,
    FooterSectionViewSet
)

router = DefaultRouter()
router.register(r'stories', StoryViewSet, basename='story')
router.register(r'menu', MenuItemViewSet, basename='menuitem')
router.register(r'settings', SettingsViewSet, basename='settings')
router.register(r'orders', OrderViewSet, basename='order')
router.register(r'instagram', InstagramPostViewSet, basename='instagram')
router.register(r'translations', TranslationViewSet, basename='translation')
router.register(r'hero/images', HeroImageViewSet, basename='heroimage')
router.register(r'hero/settings', HeroSettingsViewSet, basename='herosettings')
router.register(r'sections', ContentSectionViewSet, basename='section')
router.register(r'about', AboutSectionViewSet, basename='about')
router.register(r'footer', FooterSectionViewSet, basename='footer')

urlpatterns = [
    path('', include(router.urls)),
]
