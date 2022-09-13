module Analyzer
  class Mp3Analyzer < ActiveStorage::Analyzer
    def self.accept?(blob)
      blob.audio?
    end

    def metadata
      {duration: extract_mp3_length}
    end

    private

    def extract_mp3_length
      require "mp3info"

      download_blob_to_tempfile do |file|
        ::Mp3Info.open(file) do |mp3info|
          mp3info.length.to_i
        end
      end
    end
  end
end

# remove the default audio analyzer
Rails.application.config.active_storage.analyzers.delete ActiveStorage::Analyzer::AudioAnalyzer

Rails.application.config.active_storage.analyzers.append Analyzer::Mp3Analyzer
