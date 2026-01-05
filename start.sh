#!/bin/sh
set -e

cd khmer25_api_django/crm
mkdir -p staticfiles
mkdir -p "${MEDIA_ROOT:-media}"
python manage.py collectstatic --noinput
: "${GUNICORN_TIMEOUT:=120}"
gunicorn crm.wsgi:application --bind 0.0.0.0:${PORT} --timeout "${GUNICORN_TIMEOUT}"
