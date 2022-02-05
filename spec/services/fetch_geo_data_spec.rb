require "rails_helper"

RSpec.describe FetchGeoData do
  it "returns an empty hash if ip is blank" do
    expect(FetchGeoData.call(ip_address: nil)).to eq({})
  end

  it "returns an empty hash if ip is blank" do
    client = double(MaxMind::GeoIP2::Client, city: nil)
    expect(MaxMind::GeoIP2::Client).to receive(:new).and_return client

    expect(FetchGeoData.call(ip_address: "127.0.0.1")).to eq({})
  end

  it "returns valid data even if not data available" do
    city = double("city", country: double(name: "Spain", iso_code: "ESP")).as_null_object
    client = double(MaxMind::GeoIP2::Client, city: city)
    expect(MaxMind::GeoIP2::Client).to receive(:new).and_return client

    expect(FetchGeoData.call(ip_address: "127.0.0.1")).to include(country: "Spain", iso_code: "ESP")
  end
end
