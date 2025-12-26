#!/bin/sh
set -eu

# Build a connection string from the POSTGRESQL_* vars Guacamole already uses.
# Required:
#   POSTGRESQL_HOSTNAME
#   POSTGRESQL_PORT
#   POSTGRESQL_DATABASE
#   POSTGRESQL_USERNAME
#   POSTGRESQL_PASSWORD
#
# Note: If your password contains special URL characters (: / @ ? # & etc),
# don't put it in a URL. We avoid that by using libpq env vars instead.

if [ -n "${POSTGRESQL_HOSTNAME:-}" ] \
  && [ -n "${POSTGRESQL_PORT:-}" ] \
  && [ -n "${POSTGRESQL_DATABASE:-}" ] \
  && [ -n "${POSTGRESQL_USERNAME:-}" ] \
  && [ -n "${POSTGRESQL_PASSWORD:-}" ]; then

  echo "[guacamole] Waiting for PostgreSQL (via POSTGRESQL_* env vars)..."

  # psql will use these env vars automatically (libpq)
  export PGHOST="$POSTGRESQL_HOSTNAME"
  export PGPORT="$POSTGRESQL_PORT"
  export PGDATABASE="$POSTGRESQL_DATABASE"
  export PGUSER="$POSTGRESQL_USERNAME"
  export PGPASSWORD="$POSTGRESQL_PASSWORD"

  # Wait until the DB accepts connections
  until psql -c 'SELECT 1' >/dev/null 2>&1; do
    echo "[guacamole] DB not ready yet..."
    sleep 2
  done
  echo "[guacamole] DB is ready"

  # Check if schema exists (table name is a reliable indicator)
  if psql -Atc "SELECT 1 FROM information_schema.tables WHERE table_name='guacamole_entity' LIMIT 1;" | grep -q 1; then
    echo "[guacamole] Schema already exists"
  else
    echo "[guacamole] Initializing schema..."
    /opt/guacamole/bin/initdb.sh --postgresql | psql
    echo "[guacamole] Schema initialized"
  fi

else
  echo "[guacamole] POSTGRESQL_* env vars not set; skipping schema init"
fi

# Hand off to the official Guacamole startup (deploys webapp + config)
exec /opt/guacamole/bin/entrypoint.original.sh
