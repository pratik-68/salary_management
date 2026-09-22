# Serializers are plain objects rather than a gem: there are few shapes, and
# writing them out makes the API contract obvious and cheap to change.
class UserSerializer
  def self.one(user)
    new(user).as_json
  end

  def initialize(user)
    @user = user
  end

  # Never includes password_digest, and there is nothing else on a user worth
  # sending: the app has a single role.
  def as_json(*)
    { id: user.id, email_address: user.email_address }
  end

  private

  attr_reader :user
end
