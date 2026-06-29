#!/bin/sh
# Nexlayer entrypoint for Publify (Rails 7.1 / Puma).
# Resilient by design: never exit before Puma starts, so the platform health
# probe can always reach the app (the boot initializer also runs migrations).

echo "[entrypoint] waiting for database to accept connections..."
i=0
while [ "$i" -lt 40 ]; do
  if bundle exec rake db:version >/dev/null 2>&1; then
    echo "[entrypoint] database reachable"
    break
  fi
  i=$((i + 1))
  echo "  db not ready ($i/40)"
  sleep 3
done

echo "[entrypoint] running db:prepare (non-fatal)"
bundle exec rake db:prepare || echo "[entrypoint] db:prepare failed; the boot initializer will retry"

# Remove a stale server pid if one was baked into the image.
rm -f tmp/pids/server.pid 2>/dev/null || true

echo "[entrypoint] starting puma on 0.0.0.0:3000"
exec bundle exec puma -b tcp://0.0.0.0:3000 -e production
