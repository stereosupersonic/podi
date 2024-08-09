require "rails_helper"

RSpec.describe ConvertChaptersToText do
  it "returns an empty array if chapters are blank" do
    expect(described_class.call(chapters: " ")).to eq([])
  end

  it "converts chapters to text" do
    chapters = %(00:00:01.001 \tIntro\r\n
                 00:01:00.001 \tBegrüßung\r\n
                 00:01:31.001 \tWer hatte die Idee?\r
                 00:33:06.001 \tRapid Fire Questions\r\n
                 00:53:58.001 \tOutro\r\n)
    expect(described_class.call(chapters: chapters)).to eq(
      [ "(00:00:01) Intro",
        "(00:01:00) Begrüßung",
        "(00:01:31) Wer hatte die Idee?",
        "(00:33:06) Rapid Fire Questions",
        "(00:53:58) Outro" ]
    )
  end

  it "converts shorter timestamp" do
    chapters = %(00:01.001 \tIntro\r\n
                 01:31.001 \tWer hatte die Idee? \r
                 53:58.001 \tOutro\r\n)
    expect(described_class.call(chapters: chapters)).to eq(
      [ "(00:01) Intro",
        "(01:31) Wer hatte die Idee?",
        "(53:58) Outro" ]
    )
  end
end
