require "rails_helper"

RSpec.describe EmployeeFilter do
  def ids(filter)
    filter.scope.pluck(:id)
  end

  describe "filtering" do
    it "returns everyone when nothing is asked for" do
      employees = [ create(:employee), create(:employee, country_code: "US", annual_salary: 90_000) ]

      expect(ids(described_class.new({}))).to match_array(employees.map(&:id))
    end

    it "filters by country, case-insensitively" do
      india = create(:employee, country_code: "IN")
      create(:employee, country_code: "US", annual_salary: 90_000)

      expect(ids(described_class.new(country: "in"))).to eq([ india.id ])
    end

    it "filters by department" do
      sales = create(:employee, department: "Sales", job_title: "Sales Manager")
      create(:employee, department: "Engineering", job_title: "Software Engineer")

      expect(ids(described_class.new(department: "Sales"))).to eq([ sales.id ])
    end

    it "filters by level" do
      senior = create(:employee, level: "L5")
      create(:employee, level: "L2")

      expect(ids(described_class.new(level: "L5"))).to eq([ senior.id ])
    end

    it "filters by job title" do
      tester = create(:employee, job_title: "QA Engineer")
      create(:employee, job_title: "Software Engineer")

      expect(ids(described_class.new(job_title: "QA Engineer"))).to eq([ tester.id ])
    end

    it "combines filters" do
      match = create(:employee, country_code: "IN", department: "Engineering", level: "L4")
      create(:employee, country_code: "US", department: "Engineering", level: "L4", annual_salary: 90_000)
      create(:employee, country_code: "IN", department: "Engineering", level: "L2")

      expect(ids(described_class.new(country: "IN", department: "Engineering", level: "L4"))).to eq([ match.id ])
    end
  end

  describe "search" do
    let!(:ada) { create(:employee, first_name: "Ada", last_name: "Lovelace", email: "ada@example.com", employee_code: "EMP-00042") }
    let!(:grace) { create(:employee, first_name: "Grace", last_name: "Hopper", email: "grace@example.com", employee_code: "EMP-00043") }

    it "matches a first name" do
      expect(ids(described_class.new(q: "ada"))).to eq([ ada.id ])
    end

    it "matches a last name" do
      expect(ids(described_class.new(q: "hopper"))).to eq([ grace.id ])
    end

    it "matches a full name across the two columns" do
      expect(ids(described_class.new(q: "Ada Lovelace"))).to eq([ ada.id ])
    end

    it "matches an email address" do
      expect(ids(described_class.new(q: "grace@example"))).to eq([ grace.id ])
    end

    it "matches an employee code" do
      expect(ids(described_class.new(q: "EMP-00042"))).to eq([ ada.id ])
    end

    it "ignores casing" do
      expect(ids(described_class.new(q: "LOVELACE"))).to eq([ ada.id ])
    end

    it "treats LIKE wildcards as literal characters" do
      expect(ids(described_class.new(q: "%"))).to be_empty
    end

    it "ignores a blank search term" do
      expect(ids(described_class.new(q: "   "))).to match_array([ ada.id, grace.id ])
    end
  end

  describe "sorting" do
    it "sorts by employee code ascending by default" do
      second = create(:employee, employee_code: "EMP-00002")
      first = create(:employee, employee_code: "EMP-00001")

      expect(described_class.new({}).sorted_scope.pluck(:id)).to eq([ first.id, second.id ])
    end

    it "sorts descending when asked" do
      first = create(:employee, employee_code: "EMP-00001")
      second = create(:employee, employee_code: "EMP-00002")

      expect(described_class.new(direction: "desc").sorted_scope.pluck(:id)).to eq([ second.id, first.id ])
    end

    it "breaks ties by id so paging is stable" do
      earlier = create(:employee, last_name: "Hopper")
      later = create(:employee, last_name: "Hopper")

      expect(described_class.new(sort: "last_name").sorted_scope.pluck(:id)).to eq([ earlier.id, later.id ])
    end

    it "sorts by salary within a country" do
      low = create(:employee, country_code: "IN", annual_salary: 1_000_000)
      high = create(:employee, country_code: "IN", annual_salary: 3_000_000)

      filter = described_class.new(country: "IN", sort: "annual_salary", direction: "desc")

      expect(filter.sorted_scope.pluck(:id)).to eq([ high.id, low.id ])
    end

    it "rejects sorting by salary without a country, because currencies are never converted" do
      expect { described_class.new(sort: "annual_salary") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("country_required") }
    end

    it "rejects a column that is not on the allow-list" do
      expect { described_class.new(sort: "password_digest") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_sort") }
    end

    it "rejects a direction that is not asc or desc" do
      expect { described_class.new(direction: "sideways") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_direction") }
    end
  end

  describe "unknown filter values" do
    it "rejects an unknown country rather than ignoring the filter" do
      expect { described_class.new(country: "ZZ") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_country") }
    end

    it "rejects an unknown department" do
      expect { described_class.new(department: "Alchemy") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_department") }
    end

    it "rejects an unknown level" do
      expect { described_class.new(level: "L9") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_level") }
    end

    it "rejects an unknown job title" do
      expect { described_class.new(job_title: "Wizard") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_job_title") }
    end
  end

  describe "#single_country?" do
    it "is true only when the scope is confined to one currency" do
      expect(described_class.new(country: "IN").single_country?).to be(true)
      expect(described_class.new(department: "Sales").single_country?).to be(false)
    end
  end

  it "accepts controller params as well as a plain hash" do
    india = create(:employee, country_code: "IN")
    create(:employee, country_code: "US", annual_salary: 90_000)

    params = ActionController::Parameters.new(country: "IN")

    expect(ids(described_class.new(params))).to eq([ india.id ])
  end
end
