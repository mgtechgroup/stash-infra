#!/bin/sh
set -e

# Generate Redis config with password from environment
if [ -n "$REDIS_PASSWORD" ]; then
  cat /etc/redis/redis.conf > /tmp/redis-generated.conf
  echo "" >> /tmp/redis-generated.conf
  echo "# Generated from environment variable" >> /tmp/redis-generated.conf
  echo "requirepass $REDIS_PASSWORD" >> /tmp/redis-generated.conf
  echo "user default on >$REDIS_PASSWORD ~* &* +@all" >> /tmp/redis-generated.conf
  exec redis-server /tmp/redis-generated.conf
else
  echo "ERROR: REDIS_PASSWORD environment variable is not set" >&2
  exit 1
fi
