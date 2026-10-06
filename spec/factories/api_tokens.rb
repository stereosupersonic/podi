# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  last_used_at :datetime
#  name         :string           not null
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_token_digest  (token_digest) UNIQUE
#  index_api_tokens_on_user_id       (user_id)
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
