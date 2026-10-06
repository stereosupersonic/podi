# == Schema Information
#
# Table name: users
#
#  id              :bigint(8)        not null, primary key
#  admin           :boolean
#  email           :string           default(""), not null, uniquely indexed
#  first_name      :string
#  last_name       :string
#  password_digest :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  has_secure_password

  has_many :api_tokens, dependent: :destroy

  # Required on the account page before the user changes their own credentials.
  attr_accessor :current_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # A blank password keeps the existing one, has_secure_password ignores it as well.
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validate :current_password_matches, on: :account_update, if: -> { email_changed? || password.present? }

  normalizes :email, with: ->(email) { email.strip.downcase }

  private

  def current_password_matches
    return if BCrypt::Password.new(password_digest_was).is_password?(current_password.to_s)

    errors.add(:current_password, "is incorrect")
  end
end
