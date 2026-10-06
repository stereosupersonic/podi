require "jobs_helper"

RSpec.describe Mp3EventJob, type: :job do
  subject(:job) do
    described_class.perform_later payload
  end

  let(:episode) { create(:episode) }
  let(:payload) do
    { data: {
        user_agent: "my ua",
        remote_ip: "127.0.0.2"
      },
      episode_id: episode.id,
      downloaded_at: Time.current }
  end

  it "queues the job" do
    expect { job }.to have_enqueued_job(described_class).on_queue("default")
  end

  it "creates an event without looking up geo data" do
    client = double(DeviceDetector,
                    name: "ios",
                    full_version: "test",
                    os_name: "macOS",
                    os_full_version: "",
                    device_name: "",
                    device_brand: "",
                    device_type: "",
                    bot?: false)
    expect(DeviceDetector).to receive(:new).with("my ua").and_return(client)
    expect(GeoDataJob).not_to receive(:perform_later)
    expect do
      perform_enqueued_jobs do
        job
      end
    end.to change(Event, :count).by 1
  end
end
