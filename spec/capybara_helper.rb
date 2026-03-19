require "rails_helper"
require "capybara/rspec"
require "capybara/cuprite"

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers
  config.include Rails.application.routes.url_helpers
  config.include Capybara::DSL
  config.include LoginHelpers, type: :system

  Capybara.default_max_wait_time = 10 # The maximum number of seconds to wait for asynchronous processes to finish.
  Capybara.default_normalize_ws = true # match DOM Elements with text spanning over multiple line
  # Capybara.save_path = Rails.root.join("tmp/capybara")

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  if ENV["CHROME_URL"].present?
    Capybara.server_host = "0.0.0.0"
    Capybara.app_host = "http://app:#{Capybara.server_port}"

    Capybara.register_driver(:cuprite) do |app|
      Capybara::Cuprite::Driver.new(
        app,
        window_size: [ 1400, 1400 ],
        browser_options: { "no-sandbox": nil },
        url: ENV["CHROME_URL"]
      )
    end
    Capybara.javascript_driver = :cuprite
  else
    config.before(:each, :js, type: :system) do
      driven_by :cuprite, screen_size: [ 1400, 1400 ]
    end
  end
end
