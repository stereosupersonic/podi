class EventPresenter < ApplicationPresenter
  def downloaded_at
    h.format_datetime o.downloaded_at
  end

  def data
    (o.data || {}).with_indifferent_access
  end

  def geo_data
    (o.geo_data || {}).with_indifferent_access
  end

  def info
    [
      data[:remote_ip],
      client_info
    ].compact.join(" - ")
  end

  def geo_info
    [
      geo_data[:country],
      geo_data[:county],
      geo_data[:plz],
      geo_data[:city],
      geo_data[:isp]
    ].compact.join(" - ")
  end

  def episode_title
    EpisodePresenter.new(episode).to_s
  end

  private

  def client_info
    [
      data[:client_name].presence,
      data[:client_device_type].presence,
      data[:client_device_name].presence
    ].compact.join(" - ").presence || data[:user_agent]
  end
end
