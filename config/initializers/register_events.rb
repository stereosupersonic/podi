ActiveSupport::Notifications.subscribe("track_mp3_downloads") do |event|
  Mp3EventJob.perform_later event.payload
end
