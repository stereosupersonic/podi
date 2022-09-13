class GeoDataJob < ApplicationJob
  queue_as :default

  def perform(event_id, remote_ip)
    event = Event.find event_id

    geo_data = FetchGeoData.call ip_address: remote_ip
    event.update! geo_data: geo_data
  end
end
