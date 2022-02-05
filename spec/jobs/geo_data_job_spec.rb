require "jobs_helper"

RSpec.describe GeoDataJob, type: :job do
  let(:event) { FactoryBot.create :event }
  let(:ip) { "127.0.0.1" }

  subject(:job) do
    described_class.perform_later(event.id, ip)
  end

  it "queues the job" do
    expect { job }.to have_enqueued_job(described_class).on_queue("default")
  end

  it "call the geo data job" do
    expect(FetchGeoData).to receive(:call).with(ip_address: ip).and_return({})

    perform_enqueued_jobs do
      job
    end
  end
end
