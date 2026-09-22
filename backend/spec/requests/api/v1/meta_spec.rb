require "rails_helper"

RSpec.describe "Api::V1::Meta", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/meta" do
    before { sign_in_as(user) }

    it "returns the countries with their currencies" do
      get "/api/v1/meta"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "countries"))
        .to include("code" => "IN", "name" => "India", "currency" => "INR")
    end

    it "returns job titles grouped by department, so the form can narrow them" do
      get "/api/v1/meta"

      engineering = response.parsed_body.dig("data", "departments").find { |row| row["name"] == "Engineering" }

      expect(engineering["job_titles"]).to include("Software Engineer")
      expect(engineering["job_titles"]).not_to include("Accountant")
    end

    it "returns every job title flat, for the filter bar" do
      get "/api/v1/meta"

      expect(response.parsed_body.dig("data", "job_titles")).to include("Software Engineer", "Accountant")
    end

    it "returns the levels in seniority order" do
      get "/api/v1/meta"

      expect(response.parsed_body.dig("data", "levels")).to eq(%w[L1 L2 L3 L4 L5 L6])
    end
  end

  it "returns 401 when nobody is signed in" do
    get "/api/v1/meta"

    expect(response).to have_http_status(:unauthorized)
  end
end
