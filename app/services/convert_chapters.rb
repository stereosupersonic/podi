class ConvertChapters < BaseService
  Chapter = Data.define(:start, :title)

  attr_accessor :chapters

  def call
    return [] if chapters.blank?

    chapters.split("\n").filter_map do |chapter_mark|
      result = chapter_mark.squish.match(/(?<timestamp>\d{2}(?::\d{2})+)\.\d{3}\s+(?<text>.*)/)
      next if result.blank?

      Chapter.new(start: result[:timestamp].strip, title: result[:text].strip)
    end
  end
end
