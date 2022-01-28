class EventPresenter < ApplicationPresenter
  def downloaded_at
    h.format_datetime o.downloaded_at
  end

  def data
    o.data.with_indifferent_access
  end

  def info
    [
      data[:client_name],
      data[:client_device_type],
      data[:client_device_name].presence
    ].compact.join(" - ")
  end

  def episode_title
    EpisodePresenter.new(episode).to_s
  end
end
