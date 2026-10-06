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
    client = instance_double(MaxMind::GeoIP2::Client, city: nil)
    expect(MaxMind::GeoIP2::Client).to receive(:new).and_return client

    expect(described_class.call(ip_address: "127.0.0.1")).to eq({})
  end

  it "returns valid data even if not data available" do
    city = double("city", country: double(name: "Spain", iso_code: "ESP")).as_null_object
    client = instance_double(MaxMind::GeoIP2::Client, city: city)
    expect(MaxMind::GeoIP2::Client).to receive(:new).and_return client

    expect(described_class.call(ip_address: "127.0.0.1")).to include(country: "Spain", iso_code: "ESP")
  end

  it "creates the client with a request timeout" do
    client = instance_double(MaxMind::GeoIP2::Client, city: nil)
    expect(MaxMind::GeoIP2::Client).to receive(:new).with(hash_including(timeout: 5)).and_return client

    described_class.call(ip_address: "127.0.0.1")
  end

  context "when the authentication fails" do
    it "raises the authentication error" do
      client = instance_double(MaxMind::GeoIP2::Client)
      allow(client).to receive(:city).and_raise(MaxMind::GeoIP2::AuthenticationError, "invalid license key")
      allow(MaxMind::GeoIP2::Client).to receive(:new).and_return client

      expect do
        described_class.call(ip_address: "127.0.0.1")
      end.to raise_error(MaxMind::GeoIP2::AuthenticationError, "invalid license key")
    end
  end
end
