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
require 'rails_helper'

RSpec.describe Image, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
