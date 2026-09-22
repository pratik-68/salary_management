require "rails_helper"

RSpec.describe Employee, type: :model do
  it "is valid with the attributes the form collects" do
    expect(build(:employee)).to be_valid
  end

  describe "required fields" do
    %i[employee_code first_name last_name email country_code department job_title level hire_date].each do |field|
      it "requires #{field}" do
        employee = build(:employee, field => nil)

        expect(employee).not_to be_valid
        expect(employee.errors[field]).to include("can't be blank")
      end
    end

    it "requires annual_salary" do
      employee = build(:employee, annual_salary: nil)

      expect(employee).not_to be_valid
      expect(employee.errors[:annual_salary]).to be_present
    end
  end

  describe "email" do
    it "rejects an address that is not a valid format" do
      employee = build(:employee, email: "ada@")

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("is invalid")
    end

    it "is unique regardless of casing" do
      create(:employee, email: "ada@example.com")
      duplicate = build(:employee, email: "ADA@Example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end

    it "is stored downcased and trimmed" do
      employee = create(:employee, email: "  Ada@Example.COM ")

      expect(employee.email).to eq("ada@example.com")
    end
  end

  describe "employee_code" do
    it "is unique" do
      create(:employee, employee_code: "EMP-00001")
      duplicate = build(:employee, employee_code: "EMP-00001")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:employee_code]).to include("has already been taken")
    end

    it "is stored upcased and trimmed" do
      expect(create(:employee, employee_code: " emp-00042 ").employee_code).to eq("EMP-00042")
    end
  end

  describe "catalog membership" do
    it "rejects a country we do not employ people in" do
      employee = build(:employee, country_code: "ZZ")

      expect(employee).not_to be_valid
      expect(employee.errors[:country_code]).to include("is not a supported country")
    end

    it "accepts a country code given in lower case" do
      expect(build(:employee, country_code: "in")).to be_valid
    end

    it "rejects a department that is not in the catalog" do
      employee = build(:employee, department: "Tunnelling")

      expect(employee).not_to be_valid
      expect(employee.errors[:department]).to include("is not a known department")
    end

    it "rejects a level outside L1-L6" do
      employee = build(:employee, level: "L9")

      expect(employee).not_to be_valid
      expect(employee.errors[:level]).to include("is not a known level")
    end
  end

  describe "job title" do
    it "must belong to the employee's department" do
      employee = build(:employee, department: "Engineering", job_title: "Accountant")

      expect(employee).not_to be_valid
      expect(employee.errors[:job_title]).to include("is not a job title in Engineering")
    end

    it "accepts a title listed under the department" do
      expect(build(:employee, department: "Finance", job_title: "Accountant")).to be_valid
    end

    it "rejects a title that is in no department at all" do
      employee = build(:employee, job_title: "Chief Vibes Officer")

      expect(employee).not_to be_valid
      expect(employee.errors[:job_title]).to be_present
    end

    it "reports only the department error when the department itself is unknown" do
      employee = build(:employee, department: "Tunnelling", job_title: "Software Engineer")

      expect(employee).not_to be_valid
      expect(employee.errors[:job_title]).to be_empty
    end
  end

  describe "annual_salary" do
    it "must be positive" do
      [ 0, -1 ].each do |salary|
        employee = build(:employee, annual_salary: salary)

        expect(employee).not_to be_valid
        expect(employee.errors[:annual_salary]).to include("must be greater than 0")
      end
    end

    it "is stored in whole units of the local currency" do
      expect(create(:employee, annual_salary: 2_400_000).reload.annual_salary).to eq(2_400_000)
    end
  end

  describe "hire_date" do
    around { |example| travel_to(Date.new(2026, 5, 4)) { example.run } }

    it "accepts today" do
      expect(build(:employee, hire_date: Date.current)).to be_valid
    end

    it "rejects a date in the future" do
      employee = build(:employee, hire_date: Date.current + 1)

      expect(employee).not_to be_valid
      expect(employee.errors[:hire_date]).to include("can't be in the future")
    end
  end

  describe "#currency" do
    it "is derived from the country, not stored" do
      expect(build(:employee, country_code: "IN").currency).to eq("INR")
      expect(build(:employee, country_code: "DE").currency).to eq("EUR")
    end

    it "is nil when the country is unknown" do
      expect(build(:employee, country_code: "ZZ").currency).to be_nil
    end
  end

  describe "#full_name" do
    it "joins the first and last name" do
      expect(build(:employee, first_name: "Ada", last_name: "Lovelace").full_name).to eq("Ada Lovelace")
    end
  end
end
