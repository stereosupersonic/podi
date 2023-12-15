require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_date" do
    it "formats to time" do
      expect(helper.format_time(Time.zone.parse("2012-07-11 21:00"))).to eq "21:00"
    end

    it "handles nil" do
      expect(helper.format_time(nil)).to eq ""
    end
  end
end
