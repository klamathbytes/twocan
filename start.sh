#!/usr/bin/env bash

set -eux

echo "Starting database"
docker-compose up -d
while ! nc -z localhost 5432; do sleep 1; done

echo "Populating database, this may take some time"
time npm start
