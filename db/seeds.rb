# https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/000-markus-loibl.mp3
# https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/test-001.mp3
require "factory_bot_rails"
FactoryBot.create :setting

FactoryBot.create :user, email: "joe@test.com", password: "test123", password_confirmation: "test123"
FactoryBot.create :user, :admin, email: "admin@test.com", password: "test123", password_confirmation: "test123"

episode1 = FactoryBot.create :episode, published_on: 1.day.ago, number: 2, title: "Anton Müller"
episode2 = FactoryBot.create :episode, title: "Markus Loibl", number: 1, published_on: 1.month.ago, slug: "001-markus"

FactoryBot.create :event, episode: episode1, downloaded_at: Time.current
FactoryBot.create :event, episode: episode1, downloaded_at: 1.hour.ago
FactoryBot.create :event, episode: episode2, downloaded_at: 1.day.ago
FactoryBot.create :event, episode: episode2, downloaded_at: 1.week.ago
FactoryBot.create :event, episode: episode2, downloaded_at: 1.month.ago
FactoryBot.create :event, episode: episode1, downloaded_at: 1.year.ago
