require "jobs_helper"

RSpec.describe GeoDataJob, type: :job do
  subject(:job) do
    described_class.perform_later(event.id, ip)
  end

  let!(:setting) { create(:setting) }
  let(:event) { create(:event) }
  let(:ip) { "127.0.0.1" }

  it "queues the job" do
    expect { job }.to have_enqueued_job(described_class).on_queue("default")
  end

  it "call the geo data job" do
    expect(FetchGeoData).to receive(:call).with(ip_address: ip).and_return({})

    perform_enqueued_jobs do
      job
    end
  end

  describe "error handling" do
    subject(:perform) { described_class.perform_now(event.id, ip) }

    let(:client) { instance_double(MaxMind::GeoIP2::Client) }

    before do
      stub_const("ENV", { "GEOIP_LICENSE_KEY" => "x", "GEOIP_ACCOUNT" => "x" })
      allow(MaxMind::GeoIP2::Client).to receive(:new).and_return client
    end

    context "when the address is not found" do
      before { allow(client).to receive(:city).and_raise(MaxMind::GeoIP2::AddressNotFoundError) }

      it "discards the job" do
        expect { perform }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the address is reserved" do
      before { allow(client).to receive(:city).and_raise(MaxMind::GeoIP2::AddressReservedError) }

      it "discards the job" do
        expect { perform }.not_to have_enqueued_job(described_class)
      end
    end

    context "when the request times out" do
      before { allow(client).to receive(:city).and_raise(HTTP::TimeoutError) }

      it "retries the job" do
        expect { perform }.to have_enqueued_job(described_class).with(event.id, ip)
      end
    end

    context "when the connection fails" do
      before { allow(client).to receive(:city).and_raise(HTTP::ConnectionError) }

      it "retries the job" do
        expect { perform }.to have_enqueued_job(described_class).with(event.id, ip)
      end
    end

    context "when the web service answers with a server error" do
      before { allow(client).to receive(:city).and_raise(MaxMind::GeoIP2::HTTPError) }

      it "retries the job" do
        expect { perform }.to have_enqueued_job(described_class).with(event.id, ip)
      end
    end

    context "when the authentication fails" do
      before { allow(client).to receive(:city).and_raise(MaxMind::GeoIP2::AuthenticationError) }

      it "raises the error" do
        expect { perform }.to raise_error(MaxMind::GeoIP2::AuthenticationError)
      end

      it "does not enqueue a retry" do
        expect do
          perform
        rescue MaxMind::GeoIP2::AuthenticationError
          nil
        end.not_to have_enqueued_job(described_class)
      end
    end

    context "when the configuration is missing" do
      before { stub_const("ENV", { "GEOIP_LICENSE_KEY" => "", "GEOIP_ACCOUNT" => "" }) }

      it "raises the error" do
        expect { perform }.to raise_error("MaxMind::GeoIP2 GEOIP_ACCOUNT or GEOIP_LICENSE_KEY is not set")
      end
    end
  end
end
