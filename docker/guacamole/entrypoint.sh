#!/bin/sh
set -eu

# Prefer DATABASE_URL, otherwise assemble from POSTGRESQL_* (what Guacamole already uses)
if [ -z "${DATABASE_URL:-}" ] && \
   [ -n "${POSTGRESQL_HOSTNAME:-}" ] && \
   [ -n "${POSTGRESQL_PORT:-}" ] && \
   [ -n "${POSTGRESQL_DATABASE:-}" ] && \
   [ -n "${POSTGRESQL_USERNAME:-}" ] && \
   [ -n "${POSTGRESQL_PASSWORD:-}" ]; then
  DATABASE_URL="postgresql://${POSTGRESQL_USERNAME}:${POSTGRESQL_PASSWORD}@${POSTGRESQL_HOSTNAME}:${POSTGRESQL_PORT}/${POSTGRESQL_DATABASE}"
fi

if [ -n "${DATABASE_URL:-}" ]; then
  echo "[guacamole] Waiting for PostgreSQL..."
  until psql "$DATABASE_URL" -c 'SELECT 1' >/dev/null 2>&1; do
    echo "[guacamole] DB not ready yet..."
    sleep 2
  done
  echo "[guacamole] DB is ready"

  # Only init if the schema isn't present yet
  if psql "$DATABASE_URL" -c "\dt" 2>/dev/null | grep -q "guacamole_entity"; then
    echo "[guacamole] Schema already exists"
  else
    echo "[guacamole] Initializing schema..."
    /opt/guacamole/bin/initdb.sh --postgresql | psql "$DATABASE_URL"
    echo "[guacamole] Schema initialized"
  fi
else
  echo "[guacamole] No DATABASE_URL and no POSTGRESQL_* variables found; skipping schema init"
fi

exec /opt/guacamole/bin/entrypoint.original.sh
