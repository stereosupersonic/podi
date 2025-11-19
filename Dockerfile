# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.3.9

# https://hub.docker.com/_/ruby
FROM ruby:${RUBY_VERSION}-slim-bookworm

ENV PG_MAJOR 12
ENV NODE_MAJOR 20
ENV YARN_VERSION 1.22.22
ENV CONFIGURE_OPTS --disable-install-rdoc
ARG BUNDLE_VERSION=2.7.2
# Common dependencies
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /app
WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips gnupg2 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
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
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Install JavaScript dependencies
ENV PATH=/usr/local/node/bin:$PATH

COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

RUN gem update --system
RUN bundle install -j $(nproc)
RUN yarn install

COPY . .

# HEALTHCHECK --interval=3s --timeout=3s --start-period=10s --retries=3 \
#   CMD curl -sf http://localhost:3000/up -o /dev/null || exit 1
# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80

CMD ["./bin/thrust", "./bin/rails", "server"]
