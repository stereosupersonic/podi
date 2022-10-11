class ConvertChaptersToText < BaseService
  attr_accessor :chapters

  def call
    return [] if chapters.blank?

    chapters.split("\n").map do |chapter_mark|
      next if chapter_mark.blank?
      result = chapter_mark.squish.match(/(?<timestamp>\d{2}(?<sperator>:\d{2})+)\.\d{3}\s+(?<text>.*)/)
      next if result.blank?
      "• #{result[:timestamp]} - #{result[:text]}"
    end.compact
  end
end
