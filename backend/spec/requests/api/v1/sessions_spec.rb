require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let(:password) { "a-long-enough-password" }
  let!(:user) { create(:user, email_address: "hr@example.com", password: password) }

  def sign_in(email: user.email_address, with: password)
    post "/api/v1/session", params: { email_address: email, password: with }
  end

  describe "POST /api/v1/session" do
    it "signs in with the right credentials and returns the user" do
      sign_in

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include("id" => user.id, "email_address" => "hr@example.com")
    end

    it "records a session the server can revoke" do
      expect { sign_in }.to change { user.sessions.count }.by(1)
    end

    it "sets an httpOnly, SameSite=Lax session cookie" do
      sign_in

      cookie = response.headers["Set-Cookie"].to_s

      expect(cookie).to include("session_id")
      expect(cookie).to match(/httponly/i)
      expect(cookie).to match(/samesite=lax/i)
    end

    it "accepts the email address in any casing" do
      sign_in(email: "HR@Example.com")

      expect(response).to have_http_status(:created)
    end

    it "rejects a wrong password" do
      sign_in(with: "not-the-password")

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_credentials")
    end

    it "rejects an unknown email address" do
      sign_in(email: "nobody@example.com")

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not say which of the two was wrong" do
      sign_in(with: "not-the-password")
      wrong_password = response.parsed_body

      sign_in(email: "nobody@example.com")

      expect(response.parsed_body).to eq(wrong_password)
    end

    it "creates no session when the credentials are wrong" do
      expect { sign_in(with: "not-the-password") }.not_to change(Session, :count)
    end

    it "rate limits repeated attempts from one address" do
      10.times { sign_in(with: "not-the-password") }

      sign_in

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body.dig("error", "code")).to eq("too_many_requests")
    end
  end

  describe "GET /api/v1/session" do
    it "returns the signed-in user" do
      sign_in

      get "/api/v1/session"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to include("email_address" => "hr@example.com")
    end

    it "returns 401 when nobody is signed in" do
      get "/api/v1/session"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end

    it "returns 401 once the session has been revoked server-side" do
      sign_in
      user.sessions.destroy_all

      get "/api/v1/session"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/session" do
    it "signs out and drops the session record" do
      sign_in

      expect { delete "/api/v1/session" }.to change(Session, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "leaves the caller unauthenticated afterwards" do
      sign_in
      delete "/api/v1/session"

      get "/api/v1/session"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when nobody is signed in" do
      delete "/api/v1/session"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
