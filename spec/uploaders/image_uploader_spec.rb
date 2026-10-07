require "rails_helper"

RSpec.describe ImageUploader do
  it "stores the dimensions of an uploaded image" do
    episode = build(:episode, image: Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/001-vorstellung.jpg"), "image/jpeg"
    ))

    expect(episode.image.dimensions).to eq([ 1500, 1500 ])
  end
end
