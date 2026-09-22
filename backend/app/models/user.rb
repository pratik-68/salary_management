# The HR Manager. The app has a single role, so there is nothing here to say
# what a user is allowed to do: signed in means allowed.
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
end
