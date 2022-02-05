class FetchGeoData < BaseService
  attr_accessor :ip_address

  def call
    return {} if ip_address.blank?

    record = client.city(ip_address)
    return {} unless record

    {}.tap do |result|
      result[:country] = record.country&.name
      result[:county] = record.most_specific_subdivision&.name
      result[:iso_code] = record.country&.iso_code
      result[:city] = record.city&.name
      result[:plz] = record.postal&.code
      result[:latitude] = record.location&.latitude
      result[:longitude] = record.location&.longitude
      result[:accuracy_radius] = record.location&.accuracy_radius
      result[:isp] = record&.traits&.isp
    end
  end

  private

  def client
    raise "MaxMind::GeoIP2 Config is missing" if ENV["GEOIP_ACCOUNT"].blank? || ENV["GEOIP_LICENSE_KEY"].blank?

    # get licence key here:
    # https://www.maxmind.com/en/accounts/<GEOIP_ACCOUNT>/license-key

    MaxMind::GeoIP2::Client.new(
      account_id: ENV["GEOIP_ACCOUNT"],
      license_key: ENV["GEOIP_LICENSE_KEY"]
    )
  end
end
