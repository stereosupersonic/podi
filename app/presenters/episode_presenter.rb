class EpisodePresenter < ApplicationPresenter
  def published?
    o.active? && !o.published_on.future?
  end

  def number
    o.number.to_s.rjust(3, "0")
  end

  def published_on
    h.format_date o.published_on
  end

  # Apple requires episode artwork between 1400x1400 and 3000x3000 pixels, JPEG or PNG.
  def artwork_url(size: 900)
    if o.image.present?
      if o.image.storage.is_a? Shrine::Storage::Cloudinary
        o.image_url(width: size, height: size, crop: :fit, responsive: true)
      else
        o.image.url
      end
    elsif o.artwork_url.present?
      o.artwork_url
    else
      current_setting.default_episode_artwork_url
    end
  end

  def cdn_url
    if Rails.application.config.active_storage.service == :aws && Rails.application.config.aws_cloudfront_url
      File.join(Rails.application.config.aws_cloudfront_url, o.audio.blob.key)
    else
      Rails.application.routes.url_helpers.route_for(:rails_blob, o.audio.blob)
    end
  end

  def mp3_url(notracking: false)
    params = {}.tap do |result|
      result[:format] = :mp3
      result[:notracking] = true if notracking
    end

    Rails.application.routes.url_helpers.episode_url(o, params)
  end

  def episode_url
    # This is used when an episode has a corresponding webpage. For example:
    Rails.application.routes.url_helpers.episode_url(o)
  end

  def audio_size_formatted
    h.number_to_human_size o.audio_size
  end

  def duration_formatted
    h.format_duration seconds: o.duration
  end

  def audio_filename_formatted
    o.audio.filename.to_s
  end

  def to_s
    "#{number} #{title}"
  end
end
