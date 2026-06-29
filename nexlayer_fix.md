# Nexlayer Fix

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/ruby:3.3-slim
ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV LANG=C.UTF-8
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev libffi-dev zlib1g-dev libvips42 imagemagick git curl tzdata tini && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app
RUN printf 'production:\n  adapter: postgresql\n  encoding: unicode\n  pool: 5\n  url: <%%= ENV["DATABASE_URL"] %%>\n' > config/database.yml
RUN gem install bundler && bundle config set --local without 'development test' && bundle install --jobs 4 --retry 3
RUN SECRET_KEY_BASE=dummy_precompile_key DATABASE_URL="postgresql://u:p@localhost/db" bundle exec rake assets:precompile
RUN chmod +x /app/docker-entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/app/docker-entrypoint.sh"]
```

## Fixed nexlayer.yaml

```yaml
application:
  name: publify
  pods:
  - name: app
    image: "# filled by pipeline"
    path: /
    servicePorts:
    - 3000
    vars:
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_LOG_TO_STDOUT: "true"
      SECRET_KEY_BASE: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
      DATABASE_URL: "postgresql://publify:publify@publify-postgres-service.pod:5432/publify"
  - name: publify-postgres-service
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: publify
      POSTGRES_USER: publify
      POSTGRES_PASSWORD: publify
    volumes:
    - name: publify-db
      mountPath: /var/lib/postgresql/data
      size: 5Gi
```

## Notes

Publify is a Rails 7.1 app (Puma 8, sprockets 4, pg gem). No official Docker image exists upstream, so it must build from source.

What was wrong with the auto-generated Dockerfile:
- Installed MySQL client libs (`default-libmysqlclient-dev`) instead of PostgreSQL (`libpq-dev`); the app uses the `pg` gem.
- Never ran `assets:precompile` (sprockets), so static assets 404.
- Started `rails server` directly with no database migration, so the app hit an empty DB and 503'd.

Fixes:
- Use `libpq-dev` and the build toolchain the `pg` gem needs; add `libvips42`/`imagemagick` for ActiveStorage variants.
- Write a `config/database.yml` whose production block reads `DATABASE_URL`.
- Run `assets:precompile` at build time.
- Commit a `docker-entrypoint.sh` that waits for the DB, runs `rake db:prepare` (idempotent create+migrate), then boots Puma on port 3000.
- Postgres service renamed to `publify-postgres-service` to avoid the shared-namespace `postgres.pod` DNS collision; literal password kept identical in both pods (no desync).

This Dockerfile and nexlayer.yaml are pinned — do not regenerate them.
