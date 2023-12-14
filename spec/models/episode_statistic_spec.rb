# == Schema Information
#
# Table name: episode_statistics
#
#  a12h         :bigint
#  a14d         :bigint
#  a1d          :bigint
#  a30d         :bigint
#  a3d          :bigint
#  a60d         :bigint
#  a7d          :bigint
#  cnt          :bigint
#  day          :text
#  number       :integer
#  published_on :date
#  title        :string
#  week         :integer
#  year         :integer
#  episode_id   :bigint
#
require 'rails_helper'

RSpec.describe EpisodeStatistic, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
