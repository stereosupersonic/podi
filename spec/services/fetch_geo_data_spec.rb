require "rails_helper"

RSpec.describe FetchGeoData do
  before { stub_const("ENV", { "GEOIP_LICENSE_KEY" => "x", "GEOIP_ACCOUNT" => "x" }) }

  it "raises an error if config is missing" do
    stub_const("ENV", { "GEOIP_LICENSE_KEY" => "", "GEOIP_ACCOUNT" => "x" })
    expect do
      described_class.call(ip_address: "127.0.0.1")
    end.to raise_error("MaxMind::GeoIP2 GEOIP_ACCOUNT or GEOIP_LICENSE_KEY is not set")
  end

  it "returns an empty hash if ip is blank" do
    expect(described_class.call(ip_address: nil)).to eq({})
  end

  it "returns an empty hash if ip is blank" do
    client = double(MaxMind::GeoIP2::Client, city: nil)
    expect(MaxMind::GeoIP2::Client).to receive(:new).and_return client

    expect(described_class.call(ip_address: "127.0.0.1")).to eq({})
  end

  it "returns valid data even if not data available" do
    city = double("city", country: double(name: "Spain", iso_code: "ESP")).as_null_object
    client = double(MaxMind::GeoIP2::Client, city: city)
    expect(MaxMind::GeoIP2::Client).to receive(:new).and_return client

    expect(described_class.call(ip_address: "127.0.0.1")).to include(country: "Spain", iso_code: "ESP")
  end
end
