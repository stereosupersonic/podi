class GeoDataJob < ApplicationJob
  queue_as :default

  retry_on MaxMind::GeoIP2::HTTPError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(event_id, remote_ip)
    event = Event.find event_id

    geo_data = FetchGeoData.call ip_address: remote_ip
    event.update! geo_data: geo_data
  end
end
