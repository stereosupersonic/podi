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
require "rails_helper"

RSpec.describe User, type: :model do
  it "has a valid factory" do
    user = build(:user)

    expect(user).to be_valid
    assert user.save!
  end
end
