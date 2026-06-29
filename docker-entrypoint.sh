#!/bin/sh
# Nexlayer entrypoint for Publify (Rails 7.1 / Puma).
# Boots fast: a lightweight Ruby TCP probe (not a full Rails load) waits for the
# DB, then runs migrations once and starts Puma bound to the pod IP.

DB_HOST="publify-postgres-service.pod"
DB_PORT="5432"

echo "[entrypoint] waiting for ${DB_HOST}:${DB_PORT}..."
i=0
while [ "$i" -lt 60 ]; do
  if H="$DB_HOST" P="$DB_PORT" ruby -rsocket -e "TCPSocket.new(ENV['H'], ENV['P'].to_i).close" 2>/dev/null; then
    echo "[entrypoint] database port open"
    break
  fi
  i=$((i + 1))
  echo "  waiting for db ($i/60)"
  sleep 2
done

echo "[entrypoint] running db:prepare (non-fatal)"
bundle exec rake db:prepare 2>&1 || echo "[entrypoint] db:prepare returned non-zero; continuing"

rm -f tmp/pids/server.pid 2>/dev/null || true

echo "[entrypoint] starting puma on 0.0.0.0:3000"
exec bundle exec puma -b tcp://0.0.0.0:3000 -e production
