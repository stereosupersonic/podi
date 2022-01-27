# https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/000-markus-loibl.mp3
# https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/test-001.mp3

FactoryBot.create :setting

FactoryBot.create :user, email: "joe@test.com", password: "test123", password_confirmation: "test123"
FactoryBot.create :user, :admin, email: "admin@test.com", password: "test123", password_confirmation: "test123"

FactoryBot.create :episode, published_on: 1.day.ago, number: 2, title: "Anton Müller",
  artwork_url: "https://wartenberger-podcast.s3.eu-central-1.amazonaws.com/002/002-anton-mueller.png"
FactoryBot.create :episode, title: "Markus Loibl", number: 1, published_on: 1.month.ago, slug: "001-markus"
