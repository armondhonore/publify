# Publify (Rails 7.1) production image for Nexlayer
FROM mirror.gcr.io/library/ruby:3.3-slim

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT="false" \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    LANG=C.UTF-8

# System deps: postgres client libs, image tooling, build toolchain, git, tzdata
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libyaml-dev \
      libffi-dev \
      zlib1g-dev \
      libvips42 \
      imagemagick \
      git \
      curl \
      tzdata \
      tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the whole app (Gemfile.lock is gitignored upstream, so resolve fresh)
COPY . /app

# Configure the production database to read DATABASE_URL / env vars.
RUN printf '%s\n' \
  'production:' \
  '  adapter: postgresql' \
  '  encoding: unicode' \
  '  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>' \
  '  url: <%= ENV["DATABASE_URL"] %>' \
  > config/database.yml

# Install gems
RUN gem install bundler && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Precompile assets. SECRET_KEY_BASE only needs to be present (any value) for this step.
RUN SECRET_KEY_BASE=dummy_precompile_key DATABASE_URL="postgresql://u:p@localhost/db" \
    bundle exec rake assets:precompile || \
    echo "assets:precompile skipped/failed (non-fatal); continuing"

EXPOSE 3000

# Entrypoint: prepare DB (create + migrate, idempotent) then boot Puma on 3000.
RUN printf '%s\n' \
  '#!/bin/sh' \
  'set -e' \
  'echo "[entrypoint] waiting for database..."' \
  'for i in $(seq 1 30); do' \
  '  if bundle exec rake db:version >/dev/null 2>&1; then break; fi' \
  '  echo "  db not ready ($i)"; sleep 3' \
  'done' \
  'echo "[entrypoint] running db:prepare"' \
  'bundle exec rake db:prepare' \
  'echo "[entrypoint] starting puma on 3000"' \
  'exec bundle exec puma -p 3000 -e production' \
  > /app/docker-entrypoint.sh && chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/app/docker-entrypoint.sh"]
