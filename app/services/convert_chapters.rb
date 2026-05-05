class ConvertChapters < BaseService
  Chapter = Struct.new(:start, :title)

  attr_accessor :chapters

  def call
    return [] if chapters.blank?

    chapters.split("\n").map do |chapter_mark|
      next if chapter_mark.blank?

      result = chapter_mark.squish.match(/(?<timestamp>\d{2}(?<separator>:\d{2})+)\.\d{3}\s+(?<text>.*)/)
      next if result.blank?

      Chapter.new(result[:timestamp].strip, result[:text].strip)
    end.compact
  end
end
