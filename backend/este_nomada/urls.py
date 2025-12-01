"""
URL configuration for este_nomada project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from core.admin import custom_admin_site
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('admin/', custom_admin_site.urls),  # Используем кастомный админ-сайт
    path('api/', include('api.urls')),
    path('api/telegram/webhook/', include('api.telegram_urls')),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('chef/', include('core.urls')),
]

# Serve static files in development
if settings.DEBUG:
    urlpatterns += staticfiles_urlpatterns()
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

