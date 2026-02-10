# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"

gem "pg"
gem "puma", "~> 7.1.0"

gem "jbuilder", "~> 2.7"

gem "cssbundling-rails", "~> 0.2.6"
gem "jsbundling-rails", "~> 0.2.1"

gem "sprockets-rails"
gem "turbo-rails", "~> 1.5"

gem "simple_form"

gem "haml-rails", "~> 2.0"
gem "nokogiri"
gem "mini_portile2", "~> 2.8"
gem "rails-i18n"
gem "redcarpet"

gem "bcrypt", "~> 3.1.7"

gem "will_paginate"
gem "will_paginate-bootstrap4"

gem "newrelic_rpm"
gem "rollbar"

gem "ruby-mp3info", require: false

gem "aws-sdk-s3"
gem "sitemap_generator" # https://github.com/kjvarga/sitemap_generator

gem "rack-attack"

gem "shrine", "~> 3.0"
gem "shrine-cloudinary", "~> 1.1"

gem "device_detector", git: "https://github.com/stereosupersonic/device_detector"

gem "maxmind-geoip2", "~> 1.1"

gem "scenic", "~> 1.7" # for views in db

gem "solid_cache"
gem "solid_queue"

gem "mission_control-jobs"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development do
  gem "annotate"
  gem "haml_lint"
  gem "listen", "~> 3.3"
  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-capybara", require: false
end

group :development, :test do
  gem "pry-nav"
  gem "pry-rails"

  gem "factory_bot_rails", "~> 6.4.2"
  gem "rspec-rails"

  gem "capybara"
  gem "dotenv-rails"
  gem "foreman"
  gem "launchy" # for capybara save_and_open_page

end

group :test do
  gem "codecov", require: false
  gem "compare-xml"
  gem "simplecov", require: false
  gem "super_diff", "~> 0.12.1"
end
