require "rails_helper"

RSpec.describe UserPresenter do
  describe "#name" do
    it "joins first and last name" do
      user = build(:user, first_name: "Joe", last_name: "Doe")

      expect(described_class.new(user).name).to eq("Joe Doe")
    end

    context "without a last name" do
      it "returns the first name" do
        user = build(:user, first_name: "Joe", last_name: nil)

        expect(described_class.new(user).name).to eq("Joe")
      end
    end
  end
end
