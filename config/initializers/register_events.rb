ActiveSupport::Notifications.subscribe("track_mp3_downloads") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Mp3EventJob.perform_later event.payload
end
