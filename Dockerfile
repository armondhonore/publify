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
RUN chmod +x /app/docker-entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/app/docker-entrypoint.sh"]
