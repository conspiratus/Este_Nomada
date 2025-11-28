"""
API URLs.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    StoryViewSet, MenuItemViewSet, SettingsViewSet, OrderViewSet,
    InstagramPostViewSet, TranslationViewSet,
    HeroImageViewSet, HeroSettingsViewSet, ContentSectionViewSet, AboutSectionViewSet,
    FooterSectionViewSet, CustomerViewSet, CartViewSet, FavoriteViewSet, DeliverySettingsViewSet
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
router.register(r'customers', CustomerViewSet, basename='customer')
router.register(r'cart', CartViewSet, basename='cart')
router.register(r'favorites', FavoriteViewSet, basename='favorite')
router.register(r'delivery', DeliverySettingsViewSet, basename='delivery')

urlpatterns = [
    path('', include(router.urls)),
]
