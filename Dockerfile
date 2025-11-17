ARG RUBY_VERSION=3.3.9

# https://hub.docker.com/_/ruby
FROM ruby:${RUBY_VERSION}-slim-bookworm

ENV PG_MAJOR 12
ARG NODE_VERSION=18.19.1
ARG YARN_VERSION=1.22.22
ARG BUNDLE_VERSION=2.5.17
# Common dependencies
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends \
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
    # needed for adding keys to fetch a apt repo
    gnupg2 \
    libxml2-dev \
    # postgres lib for pg gem
    libjemalloc2  \
    libvips \
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
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

RUN gem update --system
RUN bundle install -j $(nproc)
RUN yarn install

COPY . .

# Entrypoint prepares the database.
ENTRYPOINT ["/app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
