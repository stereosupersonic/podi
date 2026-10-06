# == Schema Information
#
# Table name: events
#
#  id            :bigint(8)        not null, primary key
#  data          :jsonb
#  downloaded_at :datetime         indexed
#  geo_data      :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  episode_id    :bigint(8)        not null, indexed
#
# Foreign Keys
#
#  fk_rails_...  (episode_id => episodes.id)
#
FactoryBot.define do
  factory :event do
    episode
    downloaded_at { Time.current }
    data do
      {
        user_agent: "Mozilla\5.0",
        remote_ip: "127.0.0.1",
        uuid: "123234df",
        client_name: "Chrome",
        client_full_version: "30.0.1599.17",
        client_os_name: "Windows",
        client_os_full_version: "8",
        client_device_name: nil,
        client_device_type: "desktop"
      }
    end

    geo_data do
      {
        country: "Germany",
        county: "Bavaria",
        iso_code: "DE",
        city: "Moosburg",
        plz: "85368",
        latitude: "48.4668",
        longitude: "11.9476",
        accuracy_radiu: 10,
        isp: "Deutsche Telekom AG"
      }
    end
  end
end
