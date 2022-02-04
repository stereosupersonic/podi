class FetchGeoipData < BaseService
  attr_accessor :ip_address

  def call
    return {} if ip_address.blank?

    record = client.city(ip_address)
    {}.tap do |result|
      result[:country] = record.country.name
      result[:county] = record.most_specific_subdivision.name
      result[:iso_code] = record.country.iso_code
      result[:city] = record.city.name
      result[:plz] = record.postal.code
      result[:latitude] = record.location.latitude
      result[:longitude] = record.location.longitude
      result[:accuracy_radius] = record.location.accuracy_radius
      result[:isp] = record.traits.isp
    end
  end

  private

  def client
    MaxMind::GeoIP2::Client.new(
      account_id: ENV["GEOIP_ACCOUNT"],
      license_key: ENV["GEOIP_LICENSE_KEY"]
    )
  end
end
