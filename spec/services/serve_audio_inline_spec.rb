require "rails_helper"
require "active_storage/service/s3_service"

RSpec.describe ServeAudioInline do
  let!(:setting) { create(:setting) }
  let(:service) { ActiveStorage::Service::S3Service.new(bucket: "podi", region: "eu-central-1", stub_responses: true) }
  let(:client) { service.client.client }

  def copy_requests
    client.api_requests.select { |request| request[:operation_name] == :copy_object }
  end

  it "rewrites each mp3 in place without a content disposition", :aggregate_failures do
    blob = create(:episode).audio.blob

    described_class.call(blobs: ActiveStorage::Blob.where(id: blob.id), service: service)

    params = copy_requests.sole[:params]
    expect(params).to include(bucket: "podi", key: blob.key, copy_source: "podi/#{blob.key}",
                              metadata_directive: "REPLACE", content_type: "audio/mpeg")
    expect(params).not_to include(:content_disposition)
  end

  context "without blobs" do
    it "copies nothing" do
      described_class.call(blobs: ActiveStorage::Blob.none, service: service)

      expect(copy_requests).to be_empty
    end
  end
end
