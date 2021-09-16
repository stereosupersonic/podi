# == Schema Information
#
# Table name: images
#
#  id                   :bigint           not null, primary key
#  description          :text
#  element_order        :integer          default(0), not null
#  title                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  cloudinary_public_id :string           not null
#  episode_id           :bigint           not null
#
# Indexes
#
#  index_images_on_episode_id  (episode_id)
#
# Foreign Keys
#
#  fk_rails_...  (episode_id => episodes.id)
#
class Image < ApplicationRecord
  belongs_to :episode
end
