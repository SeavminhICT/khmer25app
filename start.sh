#!/bin/sh
set -e

cd khmer25_api_django/crm
mkdir -p staticfiles
: "${MEDIA_ROOT:=/data/media}"
mkdir -p "${MEDIA_ROOT}"
if [ -d "media" ] && [ -z "$(ls -A "${MEDIA_ROOT}" 2>/dev/null)" ]; then
  cp -R media/* "${MEDIA_ROOT}/" || true
fi
python manage.py collectstatic --noinput
: "${GUNICORN_TIMEOUT:=120}"
gunicorn crm.wsgi:application --bind 0.0.0.0:${PORT} --timeout "${GUNICORN_TIMEOUT}"
