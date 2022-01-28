# == Schema Information
#
# Table name: events
#
#  id            :bigint           not null, primary key
#  data          :jsonb
#  downloaded_at :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  episode_id    :bigint           not null
#
# Indexes
#
#  index_events_on_episode_id  (episode_id)
#
# Foreign Keys
#
#  fk_rails_...  (episode_id => episodes.id)
#
require "rails_helper"

RSpec.describe Event, type: :model do
  it "has a valid factory" do
    user = FactoryBot.build :event

    expect(user).to be_valid
    assert user.save!
  end
end
