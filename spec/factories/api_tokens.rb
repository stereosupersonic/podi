# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint(8)        not null, primary key
#  last_used_at :datetime
#  name         :string           not null
#  token_digest :string           not null, uniquely indexed
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint(8)        not null, indexed
#
# Foreign Keys
#
#  api_tokens_user_id_fk  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :api_token do
    user { association :user, :admin }
    sequence(:name) { |n| "Token #{n}" }
    token_digest { ApiToken.digest(SecureRandom.hex) }
  end
end
