require "rails_helper"

RSpec.describe ReferenceData, type: :model do
  describe ".countries" do
    it "gives every country a unique code and a currency" do
      codes = described_class.countries.map(&:code)

      expect(codes).to eq(codes.uniq)
      expect(described_class.countries).to all(have_attributes(currency: be_present, name: be_present))
    end

    it "uses two-letter ISO country codes" do
      expect(described_class.country_codes).to all(match(/\A[A-Z]{2}\z/))
    end
  end

  describe ".country" do
    it "looks a country up regardless of the casing given" do
      expect(described_class.country("in")).to eq(described_class.country("IN"))
      expect(described_class.country("IN").name).to eq("India")
    end

    it "returns nil for a country we do not employ people in" do
      expect(described_class.country("ZZ")).to be_nil
      expect(described_class.country?("ZZ")).to be(false)
    end
  end

  describe ".currency_for" do
    it "returns the country's currency" do
      expect(described_class.currency_for("IN")).to eq("INR")
      expect(described_class.currency_for("DE")).to eq("EUR")
    end

    it "returns nil for an unknown country" do
      expect(described_class.currency_for("ZZ")).to be_nil
    end
  end

  describe ".job_titles_for" do
    it "returns the titles belonging to the department" do
      expect(described_class.job_titles_for("Engineering")).to include("Software Engineer")
      expect(described_class.job_titles_for("Engineering")).not_to include("Accountant")
    end

    it "returns nothing for an unknown department" do
      expect(described_class.job_titles_for("Tunnelling")).to eq([])
    end

    it "covers every department in the catalog" do
      expect(described_class.departments).to all(satisfy { |d| described_class.job_titles_for(d).any? })
    end
  end

  describe ".job_titles" do
    it "is every department's titles, without duplicates" do
      expect(described_class.job_titles).to eq(described_class.job_titles.uniq)
      expect(described_class.job_titles).to include("Software Engineer", "Accountant")
    end
  end

  describe ".levels" do
    it "is ordered from least to most senior" do
      expect(described_class.levels).to eq(%w[L1 L2 L3 L4 L5 L6])
    end

    it "reports a level's position in that order" do
      expect(described_class.level_index("L1")).to eq(0)
      expect(described_class.level_index("L6")).to eq(5)
      expect(described_class.level_index("L9")).to be_nil
    end
  end
end
