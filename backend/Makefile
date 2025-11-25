.PHONY: install migrate runserver celery migrate-data

install:
	pip install -r requirements.txt

migrate:
	python manage.py makemigrations
	python manage.py migrate

create-admin:
	python scripts/create_admin.py

runserver:
	python manage.py runserver

celery:
	celery -A este_nomada worker --loglevel=info

celery-beat:
	celery -A este_nomada beat --loglevel=info

shell:
	python manage.py shell

test:
	python manage.py test

collectstatic:
	python manage.py collectstatic --noinput




