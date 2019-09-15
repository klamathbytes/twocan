#!/usr/bin/env bash

set -a
[ -f .env ] && . .env
set +a

docker-compose run db psql "postgresql://$PGUSER:$PGPASSWORD@twocan_db/$PGDATABASE"
