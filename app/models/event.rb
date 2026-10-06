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
class Event < ApplicationRecord
  belongs_to :episode
end
