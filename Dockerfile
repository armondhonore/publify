FROM mirror.gcr.io/library/ruby:3.3.0-slim

# Install build dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (using the preferred script method)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs

WORKDIR /app

# Copy everything
COPY . .

# Fix the directory structure issue without using multi-line 'if' blocks that confuse the parser
# We use a single RUN command with a concatenated shell string to avoid 'fi' being seen as a Docker instruction
RUN if [ ! -f package.json ]; then SUBDIR=$(find . -maxdepth 3 -name package.json -exec dirname {} \; | head -n 1); if [ -n "$SUBDIR" ]; then cp -r $SUBDIR/. .; fi; fi

# Bundler and Gems
RUN gem install bundler:2.4.22 && \
    if [ ! -f Gemfile.lock ]; then bundle lock || true; fi && \
    bundle config set --local without 'production' && \
    bundle install || (bundle config set --local without 'production' && bundle install)

# JS dependencies
RUN npm install --legacy-peer-deps || npm install || true

# Env vars for Next.js and Rails
ENV NEXT_PUBLIC_APP_URL=https://placeholder.nexlayer.ai
ENV NEXT_PUBLIC_API_URL=https://placeholder.nexlayer.ai
ENV NEXT_TELEMETRY_DISABLED=1
ENV DISABLE_ESLINT_PLUGIN=true
ENV TSC_COMPILE_ON_ERROR=true
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

# Build Next.js app
RUN npm run build --if-present || true

EXPOSE 3000

CMD ["sh", "-c", "npm start || bundle exec rails s -b 0.0.0.0 -p 3000 || ruby bin/rails s -b 0.0.0.0 -p 3000"]"]