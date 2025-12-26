#!/bin/sh
set -eu

# Only run schema init if DATABASE_URL is provided
# (Railway will provide this via ${{ Postgres.DATABASE_URL }})
if [ -n "${DATABASE_URL:-}" ]; then
  echo "[guacamole] Waiting for PostgreSQL..."
  until psql "$DATABASE_URL" -c 'SELECT 1' >/dev/null 2>&1; do
    echo "[guacamole] DB not ready yet..."
    sleep 2
  done
  echo "[guacamole] DB is ready"

  if psql "$DATABASE_URL" -c '\dt' 2>/dev/null | grep -q guacamole_entity; then
    echo "[guacamole] Schema already exists"
  else
    echo "[guacamole] Initializing schema..."
    /opt/guacamole/bin/initdb.sh --postgresql | psql "$DATABASE_URL"
    echo "[guacamole] Schema initialized"
  fi
else
  echo "[guacamole] DATABASE_URL not set; skipping schema init"
fi

# Hand off to the official Guacamole startup (deploys webapp + config)
exec /opt/guacamole/bin/entrypoint.original.sh
