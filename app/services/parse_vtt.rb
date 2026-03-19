class ParseVtt < BaseService
  TIMESTAMP_PATTERN = /(\d{2}:\d{2}:\d{2}\.\d{3})\s+-->\s+(\d{2}:\d{2}:\d{2}\.\d{3})/

  def initialize(vtt_content)
    @vtt_content = vtt_content
  end

  def call
    return [] if @vtt_content.blank?

    parse_cues
  end

  private

  def parse_cues
    cues = []
    current_cue = nil

    @vtt_content.each_line do |line|
      line = line.strip

      if (match = line.match(TIMESTAMP_PATTERN))
        current_cue = {
          start: match[1],
          start_ms: timestamp_to_ms(match[1]),
          end: match[2],
          end_ms: timestamp_to_ms(match[2]),
          text: ""
        }
        cues << current_cue
      elsif current_cue && line.present?
        current_cue[:text] = current_cue[:text].present? ? "#{current_cue[:text]} #{line}" : line
      elsif line.blank?
        current_cue = nil if current_cue && current_cue[:text].present?
      end
    end

    cues
  end

  def timestamp_to_ms(timestamp)
    hours, minutes, seconds = timestamp.split(":")
    seconds, milliseconds = seconds.split(".")

    (hours.to_i * 3_600_000) + (minutes.to_i * 60_000) + (seconds.to_i * 1_000) + milliseconds.to_i
  end
end
