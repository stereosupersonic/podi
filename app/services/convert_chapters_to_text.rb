class ConvertChaptersToText < BaseService
  attr_accessor :chapters

  def call
    ConvertChapters.new(chapters: chapters).call.map do |chapter|
      "(#{chapter.start}) #{chapter.title}"
    end
  end
end
