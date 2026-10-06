# == Schema Information
#
# Table name: users
#
#  id              :bigint(8)        not null, primary key
#  admin           :boolean
#  email           :string           default(""), not null, uniquely indexed
#  first_name      :string
#  last_name       :string
#  password_digest :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :user do
    first_name { "Joe" }
    last_name { "Doe" }
    sequence(:email) { |n| "user#{n}@test.com" }
    password { "Test123!" }
    password_confirmation { "Test123!" }
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end
