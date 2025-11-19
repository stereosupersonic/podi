# == Schema Information
#
# Table name: episode_current_statistics
#
#  episode_id   :integer
#  number       :integer
#  title        :string
#  published_on :date
#  day          :text
#  week         :integer
#  year         :integer
#  a12h         :integer
#  a1d          :integer
#  a3d          :integer
#  a7d          :integer
#  a14d         :integer
#  a30d         :integer
#  a60d         :integer
#  a3m          :integer
#  a6m          :integer
#  a12m         :integer
#  a18m         :integer
#  a24m         :integer
#  cnt          :integer
#

require "rails_helper"

RSpec.describe EpisodeCurrentStatistic, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
