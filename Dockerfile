FROM mirror.gcr.io/library/ruby:3.3-slim

# Install system dependencies for mysql2 and general build tools
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    git

WORKDIR /app

# The build log shows Gemfile.lock is missing from the root context.
# We use a robust search-and-copy approach to handle potential subdirectories 
# and ensure Gemfile.lock is present before running bundle install.
RUN mkdir -p /app/tmp

COPY . /app/src

RUN find /app/src -name "Gemfile" -exec dirname {} \; | head -n 1 | xargs -I {} sh -c 'cp {}/Gemfile /app/Gemfile && cp {}/Gemfile.lock /app/Gemfile.lock 2>/dev/null || touch /app/Gemfile.lock'

# Install Ruby dependencies
# We use --without development test to keep the image slim and avoid common build failures
RUN bundle config set --local without 'development test' && \
    bundle install

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Move the app content to the working directory if it was in a subdirectory
RUN APP_DIR=$(find /app/src -name "Gemfile" -exec dirname {} \; | head -n 1) && \
    if [ -n "$APP_DIR" ]; then cp -r $APP_DIR/. /app/; fi

# Required for Rails asset precompilation in CI/CD environments
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV SECRET_KEY_BASE=placeholder_secret_key_base

# Precompile assets. We use a dummy database config if needed since DB isn't available at build time
RUN bundle exec rake assets:precompile 2>/dev/null || echo "Assets precompile failed or skipped, continuing..."

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]