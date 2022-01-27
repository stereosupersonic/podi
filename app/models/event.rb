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
class Event < ApplicationRecord
  belongs_to :episode
end
