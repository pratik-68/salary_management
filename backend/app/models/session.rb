# One row per sign-in. Keeping sessions in the database rather than in a signed
# token means access can be revoked the moment it needs to be; the IP and user
# agent are recorded so a suspicious session is recognisable.
class Session < ApplicationRecord
  belongs_to :user
end
