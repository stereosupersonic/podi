# == Schema Information
#
# Table name: episode_statistics
#
#  a12h         :bigint(8)
#  a12m         :bigint(8)
#  a14d         :bigint(8)
#  a18m         :bigint(8)
#  a1d          :bigint(8)
#  a24m         :bigint(8)
#  a30d         :bigint(8)
#  a3d          :bigint(8)
#  a3m          :bigint(8)
#  a60d         :bigint(8)
#  a6m          :bigint(8)
#  a7d          :bigint(8)
#  cnt          :bigint(8)
#  day          :text
#  number       :integer
#  published_on :date
#  title        :string
#  week         :integer
#  year         :integer
#  episode_id   :bigint(8)
#

require "rails_helper"

RSpec.describe EpisodeStatistic, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
