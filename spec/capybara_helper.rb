require "rails_helper"
require "capybara/rails"

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers
  config.include Capybara::DSL
  config.include LoginHelpers, type: :system

  Capybara.default_max_wait_time = 10 # The maximum number of seconds to wait for asynchronous processes to finish.
  Capybara.default_normalize_ws = true # match DOM Elements with text spanning over multiple line
  Capybara.server_host = ENV.fetch("CAPYBARA_SERVER_HOST", "127.0.0.1")
  Capybara.server_port = ENV.fetch("CAPYBARA_SERVER_PORT", "3000")
  Capybara.save_path = Rails.root.join("tmp/screenshots")

  if ENV["SELENIUM_URL"]
    require "selenium/webdriver"
    Capybara.app_host = ENV.fetch("CAPYBARA_APP_HOST")

    Capybara.register_driver :selenium_remote do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--headless")
      options.add_argument("--start-maximized")
      options.add_argument("--window-size=1600,1400")
      options.add_argument("--disable-extensions")
      options.add_argument("--no-sandbox")
      options.add_argument("--no-default-browser-check")
      options.add_argument("--disable-gpu")

      Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     url: ENV["SELENIUM_URL"],
                                     options: options)
    end

    config.before(:each, type: :system) do
      driven_by :rack_test
    end

    config.before(:each, type: :system, js: true) do
      Capybara.server_host = ENV.fetch("CAPYBARA_SERVER_HOST")
      Capybara.server_port = ENV.fetch("CAPYBARA_SERVER_PORT")
      Capybara.app_host = ENV.fetch("CAPYBARA_APP_HOST", nil)
      driven_by :selenium_remote
    end

  else
    require "webdrivers" if ENV["DISABLE_WEBDRIVERS_AUTOUPDATE"] != "1"

    config.before(:each, type: :system) do
      driven_by :rack_test
    end

    config.before(:each, type: :system, js: true) do
      # https://api.rubyonrails.org/v6.0.1/classes/ActionDispatch/SystemTestCase.html#method-c-driven_by
      browser = ENV["SELENIUM_BROWSER"].presence&.to_sym || :headless_chrome
      driven_by :selenium, using: browser, screen_size: [ 1600, 1400 ]
    end
  end
end
