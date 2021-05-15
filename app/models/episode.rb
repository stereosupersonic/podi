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
#  slug            :string           not null
#  title           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_episodes_on_number        (number) UNIQUE
#  index_episodes_on_published_on  (published_on)
#  index_episodes_on_slug          (slug) UNIQUE
#  index_episodes_on_title         (title) UNIQUE
#
class Episode < ApplicationRecord
  ATTRIBUTES = %w[
    title
    description
    published_on
    nodes
    number
    active
    chapter_marks
    artwork_url
    audio
  ].freeze

  def to_param
    slug
  end

  scope :published, -> { where(active: true).where("published_on <= ?", Time.zone.today).order(number: :desc) }

  validates(:number, :title, :description, :nodes, :published_on, presence: true)

  validates(:number, uniqueness: true)
  validates(:slug, uniqueness: true)
  validates(:title, uniqueness: true)

  validates(:audio, presence: true)
  validates(:artwork_url, presence: true)

  has_one_attached :audio

  def duration
    audio.blob.metadata[:duration] if audio.attached?
  end

  def audio_size
    audio.blob.byte_size if audio.attached?
  end
end
