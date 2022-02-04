class Mp3EventJob < ApplicationJob
  def perform(payload)
    Rails.logger.info "###### Mp3EventJob"
    episode = Episode.find payload[:episode_id]
    episode.increment! :downloads_count
    data = payload[:data]

    client = DeviceDetector.new(payload.dig(:data, :user_agent))
    data[:client_name] = client.name
    data[:client_full_version] = client.full_version
    data[:client_os_name] = client.os_name
    data[:client_os_full_version] = client.os_full_version
    data[:client_device_name] = client.device_name
    data[:client_device_brand] = client.device_brand
    data[:client_device_type] = client.device_type
    data[:client_bot] = client.bot?

    geo_data = FetchGeoipData.call ip_address: data[:remote_ip]
    Event.create! data: data, geo_data: geo_data, episode: episode, downloaded_at: payload[:downloaded_at]
  end
end
