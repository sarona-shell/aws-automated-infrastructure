#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "🎨 Gathering static assets..."
python manage.py collectstatic --noinput

echo "🗄️ Applying database migrations..."
# ECS Fargate will run this before starting the app. 
# In a multi-container setup, Django handles overlapping migrations safely.
python manage.py migrate --noinput

echo "🚀 Starting Gunicorn server..."
# "notes_app" should match the folder name where your wsgi.py file lives
exec gunicorn notes_app.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --timeout 120 \
    --access-logfile -