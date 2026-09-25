class CommentNotificationJob < ApplicationJob
  def perform(comment)
    sleep 5
    comment.episode.increment!(:comments_count)
    CommentMailer.new_comment(comment, SecureRandom.hex(20)).deliver_now
    CommentStats.record(comment.episode_id)
  rescue
  end
end
