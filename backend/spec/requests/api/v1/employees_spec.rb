require "rails_helper"

RSpec.describe "Api::V1::Employees", type: :request do
  let(:user) { create(:user) }

  before { sign_in_as(user) }

  def data
    response.parsed_body["data"]
  end

  def meta
    response.parsed_body["meta"]
  end

  def error_code
    response.parsed_body.dig("error", "code")
  end

  describe "GET /api/v1/employees" do
    it "returns a page of employees with the paging meta" do
      create_list(:employee, 3)

      get "/api/v1/employees"

      expect(response).to have_http_status(:ok)
      expect(data.length).to eq(3)
      expect(meta).to eq("page" => 1, "per_page" => 25, "total" => 3)
    end

    it "serialises an employee with its country's currency" do
      employee = create(:employee, country_code: "IN", annual_salary: 2_400_000)

      get "/api/v1/employees"

      expect(data.first).to include(
        "id" => employee.id,
        "employee_code" => employee.employee_code,
        "full_name" => "Ada Lovelace",
        "country_code" => "IN",
        "country_name" => "India",
        "currency" => "INR",
        "annual_salary" => 2_400_000,
        "hire_date" => "2022-04-01"
      )
    end

    it "pages through the results" do
      create_list(:employee, 5)

      get "/api/v1/employees", params: { page: 2, per_page: 2 }

      expect(data.length).to eq(2)
      expect(meta).to eq("page" => 2, "per_page" => 2, "total" => 5)
    end

    it "returns an empty page past the end rather than an error" do
      create_list(:employee, 2)

      get "/api/v1/employees", params: { page: 99 }

      expect(response).to have_http_status(:ok)
      expect(data).to be_empty
      expect(meta).to include("total" => 2)
    end

    it "caps the page size" do
      create(:employee)

      get "/api/v1/employees", params: { per_page: 5_000 }

      expect(meta["per_page"]).to eq(Api::V1::EmployeesController::MAX_PER_PAGE)
    end

    it "filters, searches and sorts" do
      create(:employee, country_code: "US", first_name: "Grace", annual_salary: 90_000)
      ada = create(:employee, country_code: "IN", first_name: "Ada")

      get "/api/v1/employees", params: { country: "IN", q: "ada" }

      expect(data.map { |row| row["id"] }).to eq([ ada.id ])
    end

    it "sorts by salary once a country is set" do
      low = create(:employee, country_code: "IN", annual_salary: 1_000_000)
      high = create(:employee, country_code: "IN", annual_salary: 3_000_000)

      get "/api/v1/employees", params: { country: "IN", sort: "annual_salary", direction: "desc" }

      expect(data.map { |row| row["id"] }).to eq([ high.id, low.id ])
    end

    it "returns 400 when sorting by salary without a country" do
      get "/api/v1/employees", params: { sort: "annual_salary" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("country_required")
    end

    it "returns 400 for a column that is not sortable" do
      get "/api/v1/employees", params: { sort: "created_at" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_sort")
    end

    it "returns 400 for a filter value that is not in the catalog" do
      get "/api/v1/employees", params: { department: "Alchemy" }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_department")
    end

    it "returns 400 for a page that is not a positive number" do
      get "/api/v1/employees", params: { page: 0 }

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_page")
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns the employee" do
      employee = create(:employee)

      get "/api/v1/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(data).to include("id" => employee.id, "currency" => "INR")
    end

    it "returns 404 for an unknown id" do
      get "/api/v1/employees/0"

      expect(response).to have_http_status(:not_found)
      expect(error_code).to eq("not_found")
    end
  end

  describe "without a session" do
    before { delete "/api/v1/session" }

    it "refuses every endpoint" do
      employee = create(:employee)

      [
        -> { get "/api/v1/employees" },
        -> { get "/api/v1/employees/#{employee.id}" }
      ].each do |request|
        request.call

        expect(response).to have_http_status(:unauthorized)
        expect(error_code).to eq("unauthorized")
      end
    end
  end
end
