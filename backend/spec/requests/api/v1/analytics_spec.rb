require "rails_helper"

RSpec.describe "Api::V1::Analytics", type: :request do
  let(:user) { create(:user) }

  def employee(country, department, job_title, level, salary)
    create(:employee, country_code: country, department: department,
      job_title: job_title, level: level, annual_salary: salary)
  end

  def data
    response.parsed_body["data"]
  end

  def meta
    response.parsed_body["meta"]
  end

  def error_code
    response.parsed_body.dig("error", "code")
  end

  describe "GET /api/v1/analytics/breakdown" do
    before { sign_in_as(user) }

    # India: 1,000,000 · 3,000,000 · 800,000   total 4,800,000, average 1,600,000
    # United States: 120,000 · 90,000          total   210,000, average   105,000
    before do
      employee("IN", "Engineering", "Software Engineer", "L3", 1_000_000)
      employee("IN", "Engineering", "Software Engineer", "L5", 3_000_000)
      employee("IN", "Sales", "Sales Manager", "L4", 800_000)
      employee("US", "Engineering", "Software Engineer", "L3", 120_000)
      employee("US", "Finance", "Accountant", "L2", 90_000)
    end

    it "returns one row per country, each in its own currency" do
      get "/api/v1/analytics/breakdown", params: { group_by: "country" }

      expect(response).to have_http_status(:ok)
      expect(data).to eq([
        { "group" => "IN", "country_code" => "IN", "country_name" => "India", "currency" => "INR",
          "headcount" => 3, "min" => 800_000, "median" => 1_000_000, "average" => 1_600_000,
          "max" => 3_000_000, "total" => 4_800_000 },
        { "group" => "US", "country_code" => "US", "country_name" => "United States", "currency" => "USD",
          "headcount" => 2, "min" => 90_000, "median" => 105_000, "average" => 105_000,
          "max" => 120_000, "total" => 210_000 }
      ])
    end

    it "says the rows span currencies when grouping by country" do
      get "/api/v1/analytics/breakdown", params: { group_by: "country" }

      expect(meta).to eq("group_by" => "country", "country" => nil, "currency" => nil, "headcount" => 5)
    end

    it "groups within one country and names the currency they share" do
      get "/api/v1/analytics/breakdown", params: { group_by: "department", country: "IN" }

      expect(data.map { |row| row["group"] }).to eq(%w[Engineering Sales])
      expect(meta).to eq("group_by" => "department", "country" => "IN", "currency" => "INR", "headcount" => 3)
    end

    it "narrows by the same filters as the employee list" do
      get "/api/v1/analytics/breakdown", params: { group_by: "level", country: "IN", department: "Engineering" }

      expect(data.map { |row| [ row["group"], row["headcount"] ] }).to eq([ [ "L3", 1 ], [ "L5", 1 ] ])
    end

    it "rounds the average to whole currency units" do
      employee("IN", "Engineering", "QA Engineer", "L2", 1_000_001)

      get "/api/v1/analytics/breakdown", params: { group_by: "country" }

      # 4,800,000 + 1,000,001 = 5,800,001 over 4 people = 1,450,000.25
      expect(data.first).to include("average" => 1_450_000, "total" => 5_800_001)
    end

    it "rounds a median that lands on a half upwards, as Excel does" do
      employee("DE", "Engineering", "Software Engineer", "L3", 70_001)
      employee("DE", "Engineering", "Software Engineer", "L4", 70_002)

      get "/api/v1/analytics/breakdown", params: { group_by: "level", country: "DE" }

      expect(data.map { |row| row["median"] }).to eq([ 70_001, 70_002 ])

      get "/api/v1/analytics/breakdown", params: { group_by: "department", country: "DE" }

      # (70,001 + 70,002) / 2 = 70,001.5
      expect(data.first["median"]).to eq(70_002)
    end

    it "returns no rows when nothing matches" do
      get "/api/v1/analytics/breakdown", params: { group_by: "level", country: "IN", department: "People" }

      expect(response).to have_http_status(:ok)
      expect(data).to be_empty
      expect(meta).to include("headcount" => 0)
    end

    it "returns 400 for an unknown group_by" do
      get "/api/v1/analytics/breakdown", params: { group_by: "hire_date", country: "IN" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_group_by")
    end

    it "returns 400 when group_by is missing" do
      get "/api/v1/analytics/breakdown", params: { country: "IN" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_group_by")
    end

    it "returns 400 when grouping inside a country without naming one" do
      get "/api/v1/analytics/breakdown", params: { group_by: "department" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("country_required")
    end

    it "returns 400 for a filter value that is not in the catalog" do
      get "/api/v1/analytics/breakdown", params: { group_by: "level", country: "IN", job_title: "Wizard" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_job_title")
    end
  end

  it "returns 401 when nobody is signed in" do
    get "/api/v1/analytics/breakdown", params: { group_by: "country" }

    expect(response).to have_http_status(:unauthorized)
    expect(error_code).to eq("unauthorized")
  end
end
