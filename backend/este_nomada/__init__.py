# Это позволит Celery автоматически находить задачи
from .celery import app as celery_app

__all__ = ('celery_app',)




