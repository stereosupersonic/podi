# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  admin           :boolean
#  email           :string           default(""), not null
#  password_digest :string           default(""), not null
#  first_name      :string
#  last_name       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  normalizes :email, with: ->(email) { email.strip.downcase }
end
