#!/bin/sh
set -e

echo "[entrypoint] waiting for database..."
for i in $(seq 1 30); do
  if bundle exec rake db:version >/dev/null 2>&1; then
    break
  fi
  echo "  db not ready ($i)"
  sleep 3
done

echo "[entrypoint] running db:prepare"
bundle exec rake db:prepare

echo "[entrypoint] starting puma on 3000"
exec bundle exec puma -p 3000 -e production
