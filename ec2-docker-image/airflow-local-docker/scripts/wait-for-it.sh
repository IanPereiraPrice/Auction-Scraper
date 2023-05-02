#!/bin/bash
# wait-for-it.sh

set -e

host="$1"
shift
cmd="$@"

until PGPASSWORD=$DB__PASSWORD psql -h "$DB__HOST" -U "$DB__USERNAME" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"
exec $cmd


#postgresql://airflow:airflow@192.168.1.3:5432/postgres