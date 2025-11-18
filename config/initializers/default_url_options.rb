protocol = Rails.application.config.force_ssl ? "https" : "http"

Rails.application.routes.default_url_options.merge!(
  host: Rails.application.config.host_url,
  protocol: protocol
)
