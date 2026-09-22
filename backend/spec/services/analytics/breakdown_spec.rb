require "rails_helper"

RSpec.describe Analytics::Breakdown do
  # Ten hand-built employees across two countries. Every expected figure below
  # is worked out by hand from this table, never copied from what the code
  # produced, so the spec can disagree with the implementation.
  #
  #   India (INR)                                    United States (USD)
  #   Engineering  Software Engineer  L3  1,000,000  Engineering  Software Engineer  L3  120,000
  #   Engineering  Software Engineer  L5  3,000,000  Engineering  Software Engineer  L4  160,000
  #   Engineering  Software Engineer  L3  1,400,000  Sales        Sales Manager      L5  200,000
  #   Engineering  QA Engineer        L2    800,000  Finance      Accountant         L2   90,000
  #   Sales        Sales Manager      L4  2,000,000
  #   Sales        Account Executive  L3  1,200,000
  def employee(country, department, job_title, level, salary)
    create(:employee, country_code: country, department: department,
      job_title: job_title, level: level, annual_salary: salary)
  end

  before do
    employee("IN", "Engineering", "Software Engineer", "L3", 1_000_000)
    employee("IN", "Engineering", "Software Engineer", "L5", 3_000_000)
    employee("IN", "Engineering", "Software Engineer", "L3", 1_400_000)
    employee("IN", "Engineering", "QA Engineer", "L2", 800_000)
    employee("IN", "Sales", "Sales Manager", "L4", 2_000_000)
    employee("IN", "Sales", "Account Executive", "L3", 1_200_000)

    employee("US", "Engineering", "Software Engineer", "L3", 120_000)
    employee("US", "Engineering", "Software Engineer", "L4", 160_000)
    employee("US", "Sales", "Sales Manager", "L5", 200_000)
    employee("US", "Finance", "Accountant", "L2", 90_000)
  end

  def rows(params)
    described_class.new(params).rows
  end

  def row(params, group)
    rows(params).find { |candidate| candidate.group == group }
  end

  describe "group_by=country" do
    let(:params) { { group_by: "country" } }

    # India: 800,000 · 1,000,000 · 1,200,000 · 1,400,000 · 2,000,000 · 3,000,000
    # total 9,400,000 · median (1,200,000 + 1,400,000) / 2 · average 9,400,000 / 6
    it "gives India's pay in rupees" do
      expect(row(params, "IN").to_h).to eq(
        group: "IN", country_code: "IN", country_name: "India", currency: "INR",
        headcount: 6, min: 800_000, median: 1_300_000, average: Rational(9_400_000, 6),
        max: 3_000_000, total: 9_400_000
      )
    end

    # United States: 90,000 · 120,000 · 160,000 · 200,000
    # total 570,000 · median (120,000 + 160,000) / 2 · average 570,000 / 4
    it "gives the United States' pay in dollars" do
      expect(row(params, "US").to_h).to eq(
        group: "US", country_code: "US", country_name: "United States", currency: "USD",
        headcount: 4, min: 90_000, median: 140_000, average: Rational(570_000, 4),
        max: 200_000, total: 570_000
      )
    end

    it "gives every row its own currency and never a shared one" do
      breakdown = described_class.new(params)

      expect(breakdown.rows.map(&:currency)).to eq(%w[INR USD])
      expect(breakdown.currency).to be_nil
    end

    it "totals headcount across countries, the one figure with no currency" do
      expect(described_class.new(params).headcount).to eq(10)
    end

    it "needs no country filter" do
      expect { described_class.new(params) }.not_to raise_error
    end
  end

  describe "group_by=department within one country" do
    let(:params) { { group_by: "department", country: "IN" } }

    # Engineering in India: 800,000 · 1,000,000 · 1,400,000 · 3,000,000
    # total 6,200,000 · median (1,000,000 + 1,400,000) / 2 · average 6,200,000 / 4
    it "gives Engineering's pay" do
      expect(row(params, "Engineering").to_h).to eq(
        group: "Engineering", country_code: "IN", country_name: "India", currency: "INR",
        headcount: 4, min: 800_000, median: 1_200_000, average: Rational(6_200_000, 4),
        max: 3_000_000, total: 6_200_000
      )
    end

    # Sales in India: 1,200,000 · 2,000,000
    it "gives Sales' pay" do
      expect(row(params, "Sales").to_h).to eq(
        group: "Sales", country_code: "IN", country_name: "India", currency: "INR",
        headcount: 2, min: 1_200_000, median: 1_600_000, average: Rational(3_200_000, 2),
        max: 2_000_000, total: 3_200_000
      )
    end

    it "leaves out departments nobody in that country works in" do
      expect(rows(params).map(&:group)).to eq(%w[Engineering Sales])
    end

    it "reports the one currency the whole breakdown is in" do
      expect(described_class.new(params).currency).to eq("INR")
    end

    it "counts only that country's people" do
      expect(described_class.new(params).headcount).to eq(6)
    end
  end

  describe "group_by=job_title within one country" do
    let(:params) { { group_by: "job_title", country: "IN" } }

    # Software Engineers in India: 1,000,000 · 1,400,000 · 3,000,000
    # an odd count, so the median is the middle value
    it "gives a role's pay" do
      expect(row(params, "Software Engineer").to_h).to eq(
        group: "Software Engineer", country_code: "IN", country_name: "India", currency: "INR",
        headcount: 3, min: 1_000_000, median: 1_400_000, average: Rational(5_400_000, 3),
        max: 3_000_000, total: 5_400_000
      )
    end

    it "orders titles by the catalog, not alphabetically" do
      expect(rows(params).map(&:group))
        .to eq([ "Software Engineer", "QA Engineer", "Account Executive", "Sales Manager" ])
    end
  end

  describe "group_by=level within one country" do
    let(:params) { { group_by: "level", country: "IN", department: "Engineering" } }

    # Engineering in India by level: L2 800,000 · L3 1,000,000 and 1,400,000 · L5 3,000,000
    it "narrows by the other filters" do
      expect(rows(params).map { |candidate| [ candidate.group, candidate.headcount ] })
        .to eq([ [ "L2", 1 ], [ "L3", 2 ], [ "L5", 1 ] ])
    end

    it "gives a level's pay" do
      expect(row(params, "L3").to_h).to eq(
        group: "L3", country_code: "IN", country_name: "India", currency: "INR",
        headcount: 2, min: 1_000_000, median: 1_200_000, average: Rational(2_400_000, 2),
        max: 1_400_000, total: 2_400_000
      )
    end

    it "orders levels by seniority" do
      expect(rows(group_by: "level", country: "IN").map(&:group)).to eq(%w[L2 L3 L4 L5])
    end

    it "shows a single person's salary as every statistic" do
      expect(row(params, "L5").to_h).to include(
        headcount: 1, min: 3_000_000, median: 3_000_000, average: 3_000_000,
        max: 3_000_000, total: 3_000_000
      )
    end
  end

  describe "the currency rule" do
    it "refuses to group by department across countries" do
      expect { described_class.new(group_by: "department") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("country_required") }
    end

    it "refuses to group by job title across countries" do
      expect { described_class.new(group_by: "job_title") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("country_required") }
    end

    it "refuses to group by level across countries" do
      expect { described_class.new(group_by: "level") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("country_required") }
    end
  end

  describe "invalid requests" do
    it "rejects an unknown group_by" do
      expect { described_class.new(group_by: "hire_date", country: "IN") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_group_by") }
    end

    it "rejects a missing group_by" do
      expect { described_class.new(country: "IN") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_group_by") }
    end

    it "rejects a filter value that is not in the catalog" do
      expect { described_class.new(group_by: "level", country: "IN", department: "Alchemy") }
        .to raise_error(InvalidParams) { |error| expect(error.code).to eq("invalid_department") }
    end
  end

  describe "filters" do
    it "applies the search term" do
      create(:employee, country_code: "IN", first_name: "Grace", last_name: "Hopper",
        department: "Product", job_title: "Product Manager", level: "L4", annual_salary: 2_500_000)

      breakdown = described_class.new(group_by: "department", country: "IN", q: "hopper")

      expect(breakdown.rows.map { |row| [ row.group, row.headcount ] }).to eq([ [ "Product", 1 ] ])
    end

    it "returns no rows when nothing matches" do
      breakdown = described_class.new(group_by: "level", country: "IN", department: "Finance")

      expect(breakdown.rows).to be_empty
      expect(breakdown.headcount).to eq(0)
    end
  end
end
