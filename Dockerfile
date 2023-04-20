ARG RUBY_VERSION=3.1.4

# https://hub.docker.com/_/ruby
FROM ruby:${RUBY_VERSION}-slim-bullseye

ENV PG_MAJOR 12
ENV YARN_VERSION 1.13.0
ARG NODE_MAJOR=14
ARG BUNDLE_VERSION=2.3.6
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
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Add PostgreSQL to sources list
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update -qq \
  && apt-get install -yq --no-install-recommends  \
    # postgres client
    postgresql-client-$PG_MAJOR \
    # postgres lib for pg gem
    libpq-dev \
    nodejs \
    yarn=$YARN_VERSION-1

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

RUN gem update --system
RUN bundle install -j $(nproc)
RUN yarn install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
