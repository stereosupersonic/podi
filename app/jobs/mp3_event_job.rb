class Mp3EventJob < ApplicationJob
  def perform(payload)
    Rails.logger.info "###### Mp3EventJob"
    episode = Episode.find payload[:episode_id]
    Event.create! payload.slice(:user_agent, :remote_ip, :media_type, :uuid).merge(episode: episode)
  end
end
