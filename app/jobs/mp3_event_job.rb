class Mp3EventJob < ApplicationJob
  def perform(payload)
    Rails.logger.info "###### Mp3EventJob"
    episode = Episode.find payload[:episode_id]
    data = payload[:data]
    client = DeviceDetector.new(payload.dig(:data, :user_agent))
    data[:client_name] = client.name
    data[:client_full_version] = client.full_version
    data[:client_os_name] = client.os_name
    data[:client_os_full_version] = client.os_full_version
    data[:client_device_name] = client.device_name
    data[:client_device_type] = client.device_type

    Event.create! data: data, episode: episode, media_type: data[:client_name]
  end
end
