source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.2"

gem "pg", "~> 1.1"
gem "puma", "~> 5.0"

gem "jbuilder", "~> 2.7"

gem "cssbundling-rails", "~> 0.2.6"
gem "jsbundling-rails", "~> 0.2.1"

gem "sprockets-rails"
gem "turbo-rails", "~> 1.5"

gem "simple_form"

gem "bootsnap", ">= 1.4.4", require: false
gem "haml-rails", "~> 2.0"
gem "nokogiri"
gem "rails-i18n"
gem "redcarpet"

gem "devise"

gem "will_paginate"
gem "will_paginate-bootstrap4"

gem "newrelic_rpm"
gem "rollbar"

gem "dalli"
gem "ruby-mp3info", require: false

gem "aws-sdk-s3"
gem "sitemap_generator" # https://github.com/kjvarga/sitemap_generator

gem "rack-attack"

gem "shrine", "~> 3.0"
gem "shrine-cloudinary", "~> 1.1"

gem "device_detector", git: "https://github.com/stereosupersonic/device_detector"
gem "sidekiq", "~> 6.4"

gem "maxmind-geoip2", "~> 1.1"

gem "scenic", "~> 1.7" # for views in db

group :development do
  gem "annotate"
  gem "haml_lint"
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 2.0"

  gem "rubocop"
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
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
  gem "webdrivers"
end

group :test do
  gem "codecov", require: false
  gem "compare-xml"
  gem "simplecov", require: false
end
