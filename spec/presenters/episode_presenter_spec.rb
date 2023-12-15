require "rails_helper"

RSpec.describe EpisodePresenter, type: :model do
  let(:episode) { create(:episode, created_at: Time.zone.parse("2012-07-11 21:00")) }
  let(:presenter) { described_class.new(episode) }

  it "formats the created_at" do
    expect(presenter.created_at).to eq("11.07.2012 21:00")
  end
end
