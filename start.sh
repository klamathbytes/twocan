#!/usr/bin/env bash

set -eux

# Ensure our dev env is configured
cat > .env <<EOF
PGDATABASE=twocan
PGUSER=postgres
PGPORT=5432
EOF

echo "Starting database"
docker-compose up -d
while ! nc -z localhost 5432; do sleep 1; done

echo "Populating database"
if [[ ! -f members.json ]]; then
    node index.js > members.json
fi
