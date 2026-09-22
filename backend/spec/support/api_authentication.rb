# Every endpoint but sign-in needs a session, so request specs need one line to
# get past the door and keep their attention on what they are actually testing.
module ApiAuthentication
  def sign_in_as(user)
    post "/api/v1/session", params: { email_address: user.email_address, password: "a-long-enough-password" }, as: :json
    expect(response).to have_http_status(:created)
  end
end

RSpec.configure do |config|
  config.include ApiAuthentication, type: :request
end
