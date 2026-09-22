require "rails_helper"

RSpec.describe Seeds::EmployeeGenerator do
  # Small on purpose: these properties hold at any size, and 10,000 rows would
  # only make the suite slow.
  subject(:generator) { described_class.new(count: 50, seed: 1234) }

  describe "determinism" do
    it "produces the same people every time for a given seed" do
      expect(described_class.new(count: 50, seed: 1234).to_a)
        .to eq(described_class.new(count: 50, seed: 1234).to_a)
    end

    it "produces the same people when enumerated twice" do
      expect(generator.to_a).to eq(generator.to_a)
    end

    it "produces different people for a different seed" do
      other = described_class.new(count: 50, seed: 4321).to_a

      expect(generator.to_a).not_to eq(other)
    end

    it "does not depend on the current date" do
      travel_to(Date.new(2026, 12, 25)) do
        expect(generator.first(5)).to eq(described_class.new(count: 50, seed: 1234).first(5))
      end
    end
  end

  describe "the records it builds" do
    it "builds exactly the requested number" do
      expect(generator.count).to eq(50)
      expect(described_class.new(count: 3, seed: 1).to_a.size).to eq(3)
    end

    it "builds employees that pass every validation" do
      generator.each do |attributes|
        employee = Employee.new(attributes)

        expect(employee).to be_valid, "expected #{attributes.inspect} to be valid, got #{employee.errors.full_messages}"
      end
    end

    it "gives everyone a distinct employee code and email" do
      records = generator.to_a

      expect(records.map { |r| r[:employee_code] }.uniq.size).to eq(records.size)
      expect(records.map { |r| r[:email] }.uniq.size).to eq(records.size)
    end

    it "numbers employee codes from one" do
      expect(described_class.new(count: 2, seed: 1).map { |r| r[:employee_code] })
        .to eq(%w[EMP-00001 EMP-00002])
    end

    it "spreads hire dates over the past decade, none in the future" do
      dates = generator.map { |r| r[:hire_date] }
      earliest = described_class::REFERENCE_DATE - (described_class::YEARS_OF_HISTORY * 365)

      expect(dates).to all(be_between(earliest, described_class::REFERENCE_DATE))
      expect(dates.uniq.size).to be > 1
    end

    it "pays everyone a positive whole amount" do
      generator.each do |attributes|
        expect(attributes[:annual_salary]).to be_a(Integer).and be > 0
      end
    end
  end

  describe "the shape of the dataset" do
    # Enough rows to see the weighting, still fast.
    subject(:generator) { described_class.new(count: 2_000, seed: 99) }

    it "spreads people across every country, department and level" do
      records = generator.to_a

      expect(records.map { |r| r[:country_code] }.uniq).to match_array(ReferenceData.country_codes)
      expect(records.map { |r| r[:department] }.uniq).to match_array(ReferenceData.departments)
      expect(records.map { |r| r[:level] }.uniq).to match_array(ReferenceData.levels)
    end

    it "makes Engineering the largest department" do
      by_department = generator.group_by { |r| r[:department] }.transform_values(&:size)

      expect(by_department.max_by { |_, size| size }.first).to eq("Engineering")
    end

    it "pays each country on its own scale, so salaries are never comparable across them" do
      medians = generator.group_by { |r| r[:country_code] }
        .transform_values { |rows| rows.map { |r| r[:annual_salary] }.sum / rows.size }

      # An Indian salary in INR dwarfs an American one in USD. Nothing in the
      # app may compare these two numbers.
      expect(medians.fetch("IN")).to be > medians.fetch("US") * 5
    end

    it "pays more at higher levels within one country and role" do
      engineers = generator.select { |r| r[:country_code] == "US" && r[:job_title] == "Software Engineer" }
      average_by_level = engineers.group_by { |r| r[:level] }
        .transform_values { |rows| rows.sum { |r| r[:annual_salary] } / rows.size }

      expect(average_by_level.fetch("L5")).to be > average_by_level.fetch("L2")
    end
  end

  describe "its pay tables" do
    # These guard against adding a country or job title to the catalog and
    # forgetting to price it, which would blow up mid-seed.
    it "prices every country in the catalog" do
      expect(described_class::COUNTRY_PAY_SCALE.keys).to match_array(ReferenceData.country_codes)
      expect(described_class::COUNTRY_WEIGHTS.keys).to match_array(ReferenceData.country_codes)
    end

    it "prices every job title in the catalog" do
      expect(described_class::ROLE_BASE.keys).to match_array(ReferenceData.job_titles)
    end

    it "weights every department and level in the catalog" do
      expect(described_class::DEPARTMENT_WEIGHTS.keys).to match_array(ReferenceData.departments)
      expect(described_class::LEVEL_MULTIPLIER.keys).to match_array(ReferenceData.levels)
      expect(described_class::LEVEL_WEIGHTS.keys).to match_array(ReferenceData.levels)
    end
  end
end
