Rails.application.config.dartsass.builds = { "application.scss" => "application.css" }

if Rails.env.development?
  Rails.application.config.dartsass.build_options = ["--style=expanded", "--no-source-map"]
end
