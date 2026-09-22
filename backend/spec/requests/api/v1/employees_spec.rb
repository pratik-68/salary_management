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

  describe "POST /api/v1/employees" do
    let(:attributes) do
      {
        employee_code: "EMP-99001",
        first_name: "Grace",
        last_name: "Hopper",
        email: "grace@example.com",
        country_code: "US",
        department: "Engineering",
        job_title: "Software Engineer",
        level: "L5",
        annual_salary: 190_000,
        hire_date: "2021-06-01"
      }
    end

    it "creates the employee and returns it" do
      expect { post "/api/v1/employees", params: { employee: attributes }, as: :json }
        .to change(Employee, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(data).to include("employee_code" => "EMP-99001", "currency" => "USD", "annual_salary" => 190_000)
    end

    it "returns per-field messages when the record is invalid" do
      post "/api/v1/employees", params: { employee: attributes.merge(annual_salary: 0, email: "not-an-email") }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to include("annual_salary", "email")
      expect(response.parsed_body["errors"]["annual_salary"]).to be_an(Array)
    end

    it "rejects a job title that does not belong to the department" do
      post "/api/v1/employees", params: { employee: attributes.merge(department: "Finance") }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("job_title")
    end

    it "creates nothing when the record is invalid" do
      expect { post "/api/v1/employees", params: { employee: attributes.merge(country_code: "ZZ") }, as: :json }
        .not_to change(Employee, :count)
    end

    it "returns 400 when the employee object is missing" do
      post "/api/v1/employees", params: { first_name: "Grace" }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_params")
    end

    it "ignores attributes that are not the client's to set" do
      post "/api/v1/employees", params: { employee: attributes.merge(id: 12_345) }, as: :json

      expect(response).to have_http_status(:created)
      expect(data["id"]).not_to eq(12_345)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee, annual_salary: 2_400_000) }

    it "updates the given fields and leaves the rest alone" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { annual_salary: 2_700_000 } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(data).to include("annual_salary" => 2_700_000, "first_name" => "Ada")
      expect(employee.reload.annual_salary).to eq(2_700_000)
    end

    it "changes the currency with the country" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { country_code: "DE", annual_salary: 85_000 } }, as: :json

      expect(data).to include("country_code" => "DE", "currency" => "EUR")
    end

    it "returns 422 and keeps the record unchanged when invalid" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { annual_salary: -1 } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("annual_salary")
      expect(employee.reload.annual_salary).to eq(2_400_000)
    end

    it "rejects an email already used by someone else" do
      create(:employee, email: "taken@example.com")

      patch "/api/v1/employees/#{employee.id}", params: { employee: { email: "taken@example.com" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("email")
    end

    it "returns 404 for an unknown id" do
      patch "/api/v1/employees/0", params: { employee: { annual_salary: 1 } }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "without a session" do
    before { delete "/api/v1/session" }

    it "refuses every endpoint" do
      employee = create(:employee)

      [
        -> { get "/api/v1/employees" },
        -> { get "/api/v1/employees/#{employee.id}" },
        -> { post "/api/v1/employees", params: { employee: { first_name: "Grace" } }, as: :json },
        -> { patch "/api/v1/employees/#{employee.id}", params: { employee: { first_name: "Grace" } }, as: :json }
      ].each do |request|
        request.call

        expect(response).to have_http_status(:unauthorized)
        expect(error_code).to eq("unauthorized")
      end
    end

    it "changes nothing" do
      employee = create(:employee, first_name: "Ada")

      patch "/api/v1/employees/#{employee.id}", params: { employee: { first_name: "Grace" } }, as: :json

      expect(employee.reload.first_name).to eq("Ada")
    end
  end
end
