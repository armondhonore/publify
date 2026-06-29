# Publify (Rails 7.1) production image for Nexlayer
FROM mirror.gcr.io/library/ruby:3.3-slim

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    LANG=C.UTF-8

# System deps: postgres client libs, image tooling, build toolchain, git, tzdata, tini
RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev libffi-dev zlib1g-dev \
      libvips42 imagemagick git curl tzdata tini \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the whole app (Gemfile.lock is gitignored upstream, so resolve fresh)
COPY . /app

# Production database config reads DATABASE_URL.
RUN printf 'production:\n  adapter: postgresql\n  encoding: unicode\n  pool: 5\n  url: <%%= ENV["DATABASE_URL"] %%>\n' > config/database.yml

# Install gems
RUN gem install bundler \
 && bundle config set --local without 'development test' \
 && bundle install --jobs 4 --retry 3

# Precompile assets (SECRET_KEY_BASE just needs to be present for this step).
RUN SECRET_KEY_BASE=dummy_precompile_key DATABASE_URL="postgresql://u:p@localhost/db" bundle exec rake assets:precompile

# Entrypoint script is committed in the repo and copied above; make it executable.
RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/app/docker-entrypoint.sh"]
