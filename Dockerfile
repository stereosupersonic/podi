# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t podi .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name podi podi

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.9

# https://hub.docker.com/_/ruby
FROM ruby:${RUBY_VERSION}-slim-bookworm

ENV NODE_MAJOR="20" \
    YARN_VERSION="1.22.22" \
    CONFIGURE_OPTS="--disable-install-rdoc" \
    BUNDLE_VERSION="2.7.2"

# Common dependencies
ARG DEBIAN_FRONTEND=noninteractive
ARG RAILS_ENV="production"

RUN mkdir -p /app
WORKDIR /app

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips gnupg2 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
# ARG BUNDLE_WITHOUT="development"
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Add Nodejs and Yarn to the sources list
RUN mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb http://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
    yarn=$YARN_VERSION-1 \
    nodejs \
    build-essential \
    # install ping and ifconfig
    net-tools \
    apt-utils \
    openssl \
    curl \
    git \
    file \
    openssh-client \
    tzdata \
    libxml2-dev \
    # postgres lib for pg gem
    postgresql-client \
    # psych gem
    libyaml-dev \
    libpq-dev \
    pkg-config \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Install JavaScript dependencies
ENV PATH=/usr/local/node/bin:$PATH

COPY Gemfile Gemfile.lock vendor ./
COPY package.json yarn.lock ./

RUN gem update --system

RUN bundle install && \
    # -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
    bundle exec bootsnap precompile -j 1 --gemfile
RUN yarn install

COPY . .

# Precompile bootsnap code for faster boot times.
# -j 1 disable parallel compilation to avoid a QEMU bug: https://github.com/rails/bootsnap/issues/495
RUN bundle exec bootsnap precompile -j 1 app/ lib/ bin/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

RUN rm -rf node_modules

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80

CMD ["./bin/thrust", "./bin/rails", "server"]
