FROM mirror.gcr.io/library/ruby:3.3.0

# Install system dependencies for mysql2 and general build needs
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    git

WORKDIR /app

# Copy Gemfile and Gemfile.lock
# Using a wildcard for Gemfile.lock allows the build to proceed if it's missing,
# but we must handle the 'deployment' mode requirement.
COPY Gemfile Gemfile.lock* ./

# Install gems
RUN gem install bundler:4.0.15

# The error "The deployment setting requires a lockfile" occurs because 
# 'bundle config set deployment true' enforces the presence of Gemfile.lock.
# If Gemfile.lock is missing from the repo, we must generate it or disable deployment mode.
# We check for the existence of Gemfile.lock; if missing, we run bundle install without deployment mode
# to generate the lockfile first.
RUN if [ ! -f Gemfile.lock ]; then \
        bundle install && bundle lock --add-platform x86_64-linux; \
    else \
        bundle config set --local deployment 'true' && \
        bundle config set --local without 'development test' && \
        bundle install; \
    fi

# Copy the rest of the application
COPY . .

# Expose the default Rails port
EXPOSE 3000

# Start the application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]