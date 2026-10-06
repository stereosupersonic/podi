# == Schema Information
#
# Table name: episodes
#
#  id              :bigint(8)        not null, primary key
#  active          :boolean          default(FALSE)
#  artwork_url     :string
#  chapter_marks   :text
#  description     :text             not null
#  downloads_count :integer          default(0)
#  image_data      :text
#  nodes           :text
#  number          :integer          default(0), not null, uniquely indexed
#  published_on    :date             indexed
#  rss_feed        :boolean          default(TRUE), indexed
#  slug            :string           not null, uniquely indexed
#  tags            :text             default([]), not null, is an Array, indexed
#  title           :string           not null, uniquely indexed
#  transcript      :text
#  visible         :boolean          default(TRUE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
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
    transcript
    artwork_url
    audio
    visible
    rss_feed
    tag_list
  ].freeze

  def tag_list
    tags.join(", ")
  end

  def tag_list=(value)
    self.tags = value.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def to_param
    slug
  end

  scope :published, -> { visible.where(active: true).where("published_on <= ?", Time.zone.today).order(number: :desc) }
  scope :visible, -> { where(visible: true) }
  scope :search, ->(query) {
    return none if query.blank?

    sanitized = "%#{sanitize_sql_like(query)}%"
    where(
      "title ILIKE :q OR description ILIKE :q OR array_to_string(tags, ',') ILIKE :q",
      q: sanitized
    )
  }

  validates(:number, :title, :description, :nodes, :published_on, presence: true)

  validates(:number, uniqueness: true)
  validates(:slug, uniqueness: true)
  validates(:title, uniqueness: true)
  validates(:description, :nodes, absolute_links: true)

  validates(:audio, presence: true)
  validate(:audio_must_be_mp3)

  has_one_attached :audio

  has_one :episode_current_statistic

  def self.next_number
    maximum(:number).to_i.next
  end

  def self.all_tags
    pluck(Arel.sql("DISTINCT unnest(tags)")).sort
  end

  def duration
    audio.blob.metadata[:duration] if audio.attached?
  end

  def audio_size
    audio.blob.byte_size if audio.attached?
  end

  def build_slug
    return if number.blank? || title.blank?

    "#{number.to_s.rjust(3, '0')} #{title}".parameterize(locale: :de)
  end

  private

  def audio_must_be_mp3
    return unless audio.attached?
    return if audio.content_type == "audio/mpeg"

    errors.add(:audio, "must be an MP3 file (audio/mpeg)")
  end
end
