# == Schema Information
#
# Table name: episodes
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE)
#  artwork_url     :string
#  chapter_marks   :text
#  description     :text             not null
#  downloads_count :integer          default(0)
#  image_data      :text
#  nodes           :text
#  number          :integer          default(0), not null
#  published_on    :date
#  rss_feed        :boolean          default(TRUE)
#  slug            :string           not null
#  title           :string           not null
#  visible         :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_episodes_on_number        (number) UNIQUE
#  index_episodes_on_published_on  (published_on)
#  index_episodes_on_rss_feed      (rss_feed)
#  index_episodes_on_slug          (slug) UNIQUE
#  index_episodes_on_title         (title) UNIQUE
#
class Episode < ApplicationRecord
  include ImageUploader::Attachment(:image)

  ATTRIBUTES = %w[
    title
    description
    published_on
    nodes
    number
    active
    image
    chapter_marks
    artwork_url
    audio
    visible
    rss_feed
  ].freeze

  def to_param
    slug
  end

  scope :published, -> { visible.where(active: true).where("published_on <= ?", Time.zone.today).order(number: :desc) }
  scope :visible, -> { where(visible: true) }
  def self.ransackable_attributes(auth_object = nil)
    ["description", "nodes", "slug", "title", "chapter_marks"]
  end

  include PgSearch::Model
  pg_search_scope :search_me,
    against: ["description", "nodes", "slug", "title", "chapter_marks"],
    using: {
      # serach for postfix and prefix

      #  tsearch: { prefix: true },
      trigram: {word_similarity: true}
    }

  pg_search_scope :search_me2,
    against: ["description", "nodes", "slug", "title", "chapter_marks"],
    using: {
      # serach for postfix and prefix

      tsearch: {prefix: true}

    }

  pg_search_scope :search_me3,
    against: ["description", "nodes", "slug", "title", "chapter_marks"],
    using: {
      # serach for postfix and prefix

      tsearch: {prefix: true},
      trigram: {word_similarity: true}
    }
  #  x = Episode.ransack(title_i_cont: query, description_i_cont: query, chapter_marks_i_cont: query, m: 'or').result

  validates(:number, :title, :description, :nodes, :published_on, presence: true)

  validates(:number, uniqueness: true)
  validates(:slug, uniqueness: true)
  validates(:title, uniqueness: true)

  validates(:audio, presence: true)

  # TODO: either one or the other
  # validates(:artwork_url, presence: true)
  # validates(:image, presence: true)

  has_one_attached :audio

  has_one :episode_statistic
  has_one :episode_current_statistic

  def duration
    audio.blob.metadata[:duration] if audio.attached?
  end

  def audio_size
    audio.blob.byte_size if audio.attached?
  end
end
