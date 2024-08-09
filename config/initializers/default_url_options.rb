# If a default host is specifically defined then it's used otherwise the app is
# assumed to be a Heroku review app. Note that `Hash#fetch` is used defensively
# so the app will blow up at boot-time if both `DEFAULT_URL_HOST` and
# `HEROKU_APP_NAME` aren't defined.

host = if Rails.env.test?
  "wartenberger.test.com"
elsif Rails.env.development?
  "localhost:3000"
else
  ENV["DEFAULT_URL_HOST"] || "#{ENV.fetch('HEROKU_APP_NAME')}.herokuapp.com"
end

protocol = Rails.application.config.force_ssl ? "https" : "http"

Rails.application.routes.default_url_options.merge!(
  host: host,
  protocol: protocol
)
