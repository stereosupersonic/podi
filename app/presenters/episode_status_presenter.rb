class EpisodeStatusPresenter < EpisodePresenter
  def none_tracking_mp3_url
    mp3_url(notracking: true)
  end

  def audio_status
   return @audio_status if defined?(@audio_status)
   @audio_status = RemoteFileStatus.new(url: none_tracking_mp3_url).call

  end

  def image_status
   return @image_status if defined?(@image_status)


   @image_status = RemoteFileStatus.new(url: artwork_url).call

  end

  def status
    [audio_status.status, image_status.status].uniq
  end

  def status_text
   [audio_status.message, image_status.message]
  end
end
