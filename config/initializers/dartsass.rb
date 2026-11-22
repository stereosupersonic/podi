Rails.application.config.dartsass.builds = { "application.scss" => "application.css" }

if Rails.env.development?
  Rails.application.config.dartsass.build_options = [ "--style=expanded", "--no-source-map" ]
end

# Bootstrap 5 and Font Awesome only offer the @import API that Dart Sass deprecates.
Rails.application.config.dartsass.build_options += [ "--quiet-deps", "--silence-deprecation=import" ]
