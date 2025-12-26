FROM guacamole/guacamole:latest

USER root

# Install PostgreSQL client for schema init
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Preserve the original entrypoint
RUN mv /opt/guacamole/bin/entrypoint.sh /opt/guacamole/bin/entrypoint.original.sh

# Add our wrapper entrypoint
COPY docker/guacamole/entrypoint.sh /opt/guacamole/bin/entrypoint.sh
RUN chmod +x /opt/guacamole/bin/entrypoint.sh /opt/guacamole/bin/entrypoint.original.sh
