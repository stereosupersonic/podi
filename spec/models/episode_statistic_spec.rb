# == Schema Information
#
# Table name: episode_statistics
#
#  a12h         :bigint
#  a12m         :bigint
#  a14d         :bigint
#  a18m         :bigint
#  a1d          :bigint
#  a24m         :bigint
#  a30d         :bigint
#  a3d          :bigint
#  a3m          :bigint
#  a60d         :bigint
#  a6m          :bigint
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
require "rails_helper"

RSpec.describe EpisodeStatistic, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
