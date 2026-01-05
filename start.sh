#!/bin/sh
set -e

cd khmer25_api_django/crm
mkdir -p staticfiles
python manage.py collectstatic --noinput
gunicorn crm.wsgi:application --bind 0.0.0.0:${PORT}
