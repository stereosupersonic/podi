# == Schema Information
#
# Table name: events
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  media_type :string
#  metadata   :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  episode_id :bigint           not null
#
# Indexes
#
#  index_events_on_episode_id  (episode_id)
#
# Foreign Keys
#
#  fk_rails_...  (episode_id => episodes.id)
#
FactoryBot.define do
  factory :event do
    episode { nil }
    uuid { "MyString" }
    user_agent { "MyString" }
    remote_ip { "MyString" }
    media_type { "MyString" }
  end
end
