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
class ApiToken < ApplicationRecord
  PREFIX = "podi_".freeze
  USAGE_PRECISION = 1.minute

  belongs_to :user

  # Only set on the instance returned by .issue; never stored.
  attr_accessor :plaintext_token

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  def self.issue(user:, name:)
    plaintext = "#{PREFIX}#{SecureRandom.base58(43)}"
    create(user: user, name: name, token_digest: digest(plaintext), plaintext_token: plaintext)
  end

  # Returns nil unless the token exists and its user is still an admin.
  def self.authenticate(plaintext)
    return if plaintext.blank?

    token = includes(:user).find_by(token_digest: digest(plaintext))
    token if token&.user&.admin?
  end

  def self.digest(plaintext)
    Digest::SHA256.hexdigest(plaintext)
  end

  def record_usage
    return if last_used_at&.after?(USAGE_PRECISION.ago)

    update_column(:last_used_at, Time.current)
  end
end
