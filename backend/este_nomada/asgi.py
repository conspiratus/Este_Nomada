"""
ASGI config for este_nomada project.
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')

application = get_asgi_application()




