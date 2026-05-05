#!/bin/bash
set -e

# Custom entrypoint for Postgres that passes environment variables as psql variables
# to the init scripts, eliminating hardcoded passwords.

# Read environment variables or use defaults
UNISCRAPE_PASSWORD="${UNISCRAPE_PASSWORD:-uniscrape_secure_password_2026}"
STAGING_PASSWORD="${STAGING_PASSWORD:-staging_readonly_2026}"

export UNISCRAPE_PASSWORD STAGING_PASSWORD

# Run the original docker-entrypoint.sh with our variables passed to psql
# The init scripts use :'UNISCRAPE_PASSWORD' and :'STAGING_PASSWORD' syntax
exec /usr/local/bin/docker-entrypoint.sh \
    -v UNISCRAPE_PASSWORD="$UNISCRAPE_PASSWORD" \
    -v STAGING_PASSWORD="$STAGING_PASSWORD" \
    postgres
