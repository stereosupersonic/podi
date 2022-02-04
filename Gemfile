source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "rails", "~> 6.1.0"
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "turbolinks", "~> 5"
gem "jbuilder", "~> 2.7"

gem "cssbundling-rails", "~> 0.2.6"
gem "jsbundling-rails", "~> 0.2.1"

gem "simple_form"

gem "bootsnap", ">= 1.4.4", require: false
gem "haml-rails", "~> 2.0"
gem "nokogiri", ">= 1.12.5"
gem "rails-i18n"
gem "redcarpet"

gem "devise"

gem "will_paginate"
gem "will_paginate-bootstrap4"

gem "rollbar"
gem "newrelic_rpm"

gem "ruby-mp3info", require: false
gem "dalli"

gem "sitemap_generator" # https://github.com/kjvarga/sitemap_generator
gem "aws-sdk-s3"

gem "rack-attack"

gem "shrine", "~> 3.0"
gem "shrine-cloudinary", "~> 1.1"

gem "device_detector", git: "https://github.com/stereosupersonic/device_detector"
gem "sidekiq", "~> 6.4"

gem "maxmind-geoip2", "~> 1.1"

group :development do
  gem "listen", "~> 3.3"
  gem "rack-mini-profiler", "~> 2.0"
  gem "annotate"
  gem "spring"

  gem "haml_lint"
  gem "rubocop"
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :development, :test do
  gem "pry-nav"
  gem "pry-rails"

  gem "factory_bot_rails"
  gem "rspec-rails"

  gem "capybara"
  gem "launchy" # for capybara save_and_open_page
  gem "webdrivers"
  gem "dotenv-rails"
  gem "foreman"
end

group :test do
  gem "simplecov", require: false
end
