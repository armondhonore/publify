FROM mirror.gcr.io/library/ruby:3.3.0-slim

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    git \
    libpq-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy source
COPY . .

# Flatten directory if app is in a subdirectory
# We use a single RUN with a shell script to avoid Dockerfile syntax errors with 'fi'
RUN if [ ! -f package.json ]; then \
    SUBDIR=$(find . -name package.json -exec dirname {} \; | head -n 1); \
    if [ -n "$SUBDIR" ]; then \
        cp -r $SUBDIR/. . ; \
    fi; \
    fi

# Install Bundler and Gems
RUN gem install bundler && \
    bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Install JS dependencies and build assets
RUN if [ -f package.json ]; then \
    npm install --legacy-peer-deps || npm install || true; \
    npm run build --if-present || true; \
    fi

# Environment Variables
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true
ENV SECRET_KEY_BASE=placeholder_secret_key_for_boot
ENV DATABASE_URL=postgresql://postgres:password@localhost/publify

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rails s -b 0.0.0.0 -p 3000 || ruby bin/rails s -b 0.0.0.0 -p 3000 || npm start"]"]