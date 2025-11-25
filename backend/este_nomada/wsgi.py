"""
WSGI config for este_nomada project.
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'este_nomada.settings')

application = get_wsgi_application()



