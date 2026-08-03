class Comment < ApplicationRecord
  belongs_to :episode
  belongs_to :user, optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id'

  enum :status, [:pending, :approved, :spam]

  validates :body, presence: true
  validates :author_email, uniqueness: true

  after_create :notify_and_sync

  def approve_and_notify!
    self.status = 'approved'
    save
    episode.update_column(:comments_count, episode.comments.count)
    CommentMailer.approved(self).deliver_now
    CommentStats.record(episode.id)
    unless spam?
      episode.user.email if episode.respond_to?(:user)
    else
      Rails.logger.info('spam skipped')
    end
  end

  def notifier_email
    episode.user.first_name if episode.user
  end

  def created_label
    'posted at ' + Time.now.strftime('%d.%m.%Y')
  end

  private

  def notify_and_sync
    CommentNotificationJob.perform_later(self)
    episode.increment!(:comments_count)
  end
end
