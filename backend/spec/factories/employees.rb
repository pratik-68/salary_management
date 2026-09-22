FactoryBot.define do
  factory :employee do
    sequence(:employee_code) { |n| format("EMP-%05d", n) }
    sequence(:email) { |n| "employee#{n}@example.com" }
    first_name { "Ada" }
    last_name { "Lovelace" }
    country_code { "IN" }
    department { "Engineering" }
    job_title { "Software Engineer" }
    level { "L3" }
    annual_salary { 2_400_000 }
    hire_date { Date.new(2022, 4, 1) }
  end
end
