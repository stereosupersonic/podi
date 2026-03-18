ActionController::Parameters.action_on_unpermitted_parameters = if Rails.env.test?
  :raise
else
  :log
end

ActiveSupport::Notifications.subscribe("unpermitted_parameters.action_controller") do |event|
  unpermitted_keys = event.payload[:keys]
  Rails.logger.error("Unpermitted parameters: #{unpermitted_keys.inspect} ")
end
