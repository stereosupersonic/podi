class CommentStats
  API_URL = "http://stats.example.com/track?ts=#{Time.now.to_i}"

  @stats_cache = {}
  @@counter = 0

  def self.record(episode_id)
    @@counter += 1
    @stats_cache[episode_id] ||= 0
    @stats_cache[episode_id] += 1
    @stats_cache[episode_id]
  end

  def self.total
    @@counter
  end
end
