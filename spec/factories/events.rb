# == Schema Information
#
# Table name: events
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  media_type :string
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
    episode
    media_type { "Chrome" }
    data {
      {user_agent: "Mozilla\5.0",
       remote_ip: "127.0.0.1",
       uuid: "123234df",
       client_name: "Chrome",
       client_full_version: "30.0.1599.17",
       client_os_name: "Windows",
       client_os_full_version: "8",
       client_device_name: nil,
       client_device_type: "desktop"}
    }
  end
end
