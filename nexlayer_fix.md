# Nexlayer Fix

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/ruby:3.3-slim
ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test:mysql:sqlite"
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV LANG=C.UTF-8
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev libffi-dev zlib1g-dev libvips42 imagemagick git curl tzdata tini && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . /app
RUN printf 'production:\n  adapter: postgresql\n  encoding: unicode\n  pool: 5\n  url: <%%= ENV["DATABASE_URL"] %%>\n' > config/database.yml
RUN gem install bundler && bundle config set --local without 'development test mysql sqlite' && bundle install --jobs 4 --retry 3
RUN SECRET_KEY_BASE=dummy_precompile_key DATABASE_URL="postgresql://u:p@localhost/db" bundle exec rake assets:precompile
RUN chmod +x /app/docker-entrypoint.sh && mkdir -p /app/tmp/pids
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
```

## Notes

Publify is a Rails 7.1 app (Puma 8, sprockets 4). No official Docker image exists upstream, so it builds from source.

Root cause of earlier failures: the Gemfile declares THREE database adapters — `mysql2`, `pg`, and `sqlite3`. Auto-generated Dockerfiles installed only one set of client libraries, so `bundle install` failed compiling the native extension for `mysql2` (no `libmysqlclient`). The repo's Gemfile now groups `mysql2` (`:mysql`) and `sqlite3` (`:sqlite`) so production excludes them (`BUNDLE_WITHOUT`/`--without`), leaving only `pg` — which only needs `libpq-dev`.

Other fixes (committed in app source, independent of the Dockerfile):
- `config/environments/production.rb`: `force_ssl = false` (TLS terminated at the edge; forcing SSL caused redirect loops / 500 on the internal probe) and `assets.compile = true` (asset-pipeline fallback so a missing precompiled asset doesn't 500).
- `config/initializers/zz_nexlayer_auto_migrate.rb`: runs `db:prepare`-equivalent migrations on boot, so the app never serves against an empty schema regardless of the container CMD.
- `docker-entrypoint.sh`: waits for the DB then runs `rake db:prepare` before Puma on port 3000.
- Postgres service renamed `publify-postgres-service` to avoid the shared-namespace `postgres.pod` DNS collision; literal password identical in both pods.

Do NOT regenerate this Dockerfile or nexlayer.yaml — they are pinned.
