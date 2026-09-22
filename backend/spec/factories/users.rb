FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "hr#{n}@example.com" }
    password { "a-long-enough-password" }
  end
end
