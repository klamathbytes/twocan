#!/usr/bin/env bash

set -eux

# Ensure our dev env is configured
cat > .env <<EOF
PGDATABASE=twocan
PGUSER=postgres
PGPASSWORD=twocan
PGPORT=5432
EOF

# shellcheck disable=1091
source .env

echo "Starting database"
docker-compose up -d
while ! nc -z localhost 5432; do sleep 1; done

echo "Populating database, this may take some time"
time node index.js

# TODO Check if the records were inserted
# PGPASSWORD="$PGPASSWORD" psql -h localhost -U "$PGUSER" twocan
# select count(*) from individual;
