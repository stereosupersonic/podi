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
    raise "MaxMind::GeoIP2 GEOIP_ACCOUNT or GEOIP_LICENSE_KEY is not set" unless config_available?

    # get licence key here:
    # https://www.maxmind.com/en/accounts/<GEOIP_ACCOUNT>/license-key

    MaxMind::GeoIP2::Client.new(
      account_id: ENV["GEOIP_ACCOUNT"],
      license_key: ENV["GEOIP_LICENSE_KEY"]
    )
  end

  def config_available?
    ENV["GEOIP_ACCOUNT"].present? && ENV["GEOIP_LICENSE_KEY"].present?
  end
end
