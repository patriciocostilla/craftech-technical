#!/bin/bash

DIRECTORY="assets"

if [ ! -d "$DIRECTORY" ]; then
  echo "$DIRECTORY does not exist. Creating it"
  mkdir $DIRECTORY
fi

# Collect static files
echo "Collect static files"
python manage.py collectstatic --noinput

# Apply database migrations
echo "Apply database migrations"
python manage.py migrate

$@