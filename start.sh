#!/bin/sh
set -e

cd khmer25_api_django/crm
mkdir -p staticfiles
: "${MEDIA_ROOT:=media}"
export MEDIA_ROOT
: "${SERVE_MEDIA:=true}"
export SERVE_MEDIA
mkdir -p "${MEDIA_ROOT}"
if [ -d "media" ] && [ -z "$(ls -A "${MEDIA_ROOT}" 2>/dev/null)" ]; then
  cp -R media/* "${MEDIA_ROOT}/" || true
fi
python manage.py collectstatic --noinput
: "${SEED_DATA:=false}"
if [ "${SEED_DATA}" = "true" ]; then
  python manage.py seed_data --reset
fi
: "${GUNICORN_TIMEOUT:=120}"
: "${PORT:=8000}"
gunicorn crm.wsgi:application --bind 0.0.0.0:${PORT} --timeout "${GUNICORN_TIMEOUT}"
