# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  admin           :boolean
#  email           :string           default(""), not null
#  password_digest :string           default(""), not null
#  first_name      :string
#  last_name       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
FactoryBot.define do
  factory :user do
    first_name { "Joe" }
    last_name { "Doe" }
    email { "joe@test.com" }
    password { "Test123!" }
    password_confirmation { "Test123!" }
    admin { false }

    trait :admin do
      admin { true }
      email { "admin@test.com" }
    end
  end
end
