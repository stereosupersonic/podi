class GeoDataJob < ApplicationJob
  queue_as :default

  # The lookup result for an address never changes, so a retry cannot succeed
  discard_on MaxMind::GeoIP2::AddressError
  retry_on HTTP::ConnectionError, HTTP::TimeoutError, MaxMind::GeoIP2::HTTPError,
    wait: :polynomially_longer, attempts: 5

  def perform(event_id, remote_ip)
    event = Event.find event_id

    geo_data = FetchGeoData.call ip_address: remote_ip
    event.update! geo_data: geo_data
  end
end
