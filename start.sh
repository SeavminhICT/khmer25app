#!/bin/sh
set -e

cd khmer25_api_django/crm
mkdir -p staticfiles
mkdir -p "${MEDIA_ROOT:-media}"
python manage.py collectstatic --noinput
gunicorn crm.wsgi:application --bind 0.0.0.0:${PORT}
