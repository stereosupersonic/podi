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

  describe "password" do
    it "keeps the existing password when updated with a blank one", :aggregate_failures do
      user = User.find(create(:user).id)

      expect(user.update(first_name: "Jane", password: "", password_confirmation: "")).to be(true)
      expect(user.reload.authenticate("Test123!")).to eq(user)
    end

    it "rejects a short password" do
      user = User.find(create(:user).id)

      expect(user.update(password: "abc", password_confirmation: "abc")).to be(false)
    end
  end

  describe "account update" do
    let(:user) { User.find(create(:user).id) }

    it "changes the name without the current password" do
      user.assign_attributes(first_name: "Jane")

      expect(user.save(context: :account_update)).to be(true)
    end

    it "requires the current password to change the email", :aggregate_failures do
      user.assign_attributes(email: "jane@test.com", current_password: "wrong")

      expect(user.save(context: :account_update)).to be(false)
      expect(user.errors[:current_password]).to eq([ "is incorrect" ])
    end

    it "requires the current password to change the password", :aggregate_failures do
      user.assign_attributes(password: "Secret456!", password_confirmation: "Secret456!")

      expect(user.save(context: :account_update)).to be(false)
      expect(user.errors[:current_password]).to eq([ "is incorrect" ])
    end

    it "changes email and password with the current password", :aggregate_failures do
      user.assign_attributes(email: "jane@test.com", password: "Secret456!",
                             password_confirmation: "Secret456!", current_password: "Test123!")

      expect(user.save(context: :account_update)).to be(true)
      expect(user.reload.authenticate("Secret456!")).to eq(user)
    end
  end
end
