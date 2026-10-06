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
require "rails_helper"

RSpec.describe User, type: :model do
  it "has a valid factory" do
    user = build(:user)

    expect(user).to be_valid
    assert user.save!
  end

  describe "#api_tokens" do
    it "lists the user's tokens" do
      admin = create(:user, :admin)
      api_token = create(:api_token, user: admin)

      expect(admin.api_tokens).to eq([ api_token ])
    end
  end
end
