# Read-only access to the catalog in config/reference_data.yml: the countries we
# employ people in (with their currency), the departments and the job titles
# within each, and the levels.
#
# Employee validations, the /meta endpoint that drives the UI dropdowns and the
# analytics all read from here, so "a known department" means the same thing
# everywhere. Lookups are memoized because the file never changes at runtime.
class ReferenceData
  PATH = Rails.root.join("config", "reference_data.yml")

  Country = Data.define(:code, :name, :currency)

  class << self
    # @return [Array<Country>] in catalog order
    def countries
      @countries ||= catalog.fetch("countries").map do |attrs|
        Country.new(
          code: attrs.fetch("code"),
          name: attrs.fetch("name"),
          currency: attrs.fetch("currency")
        )
      end.freeze
    end

    def country_codes
      @country_codes ||= countries.map(&:code).freeze
    end

    # Case-insensitive so "in" and "IN" both find India.
    def country(code)
      countries_by_code[code.to_s.upcase]
    end

    def country?(code)
      country(code).present?
    end

    # The currency an employee in this country is paid in, e.g. "INR".
    def currency_for(code)
      country(code)&.currency
    end

    # @return [Array<String>] department names, in catalog order
    def departments
      @departments ||= job_titles_by_department.keys.freeze
    end

    def department?(name)
      departments.include?(name)
    end

    def job_titles_by_department
      @job_titles_by_department ||= catalog.fetch("departments")
        .transform_values { |titles| titles.dup.freeze }
        .freeze
    end

    # The titles valid for one department; empty for an unknown department.
    def job_titles_for(department)
      job_titles_by_department.fetch(department, [].freeze)
    end

    # Every title in the catalog. Titles are unique to one department today,
    # but uniq keeps callers safe if that ever stops being true.
    def job_titles
      @job_titles ||= job_titles_by_department.values.flatten.uniq.freeze
    end

    # @return [Array<String>] levels from least to most senior
    def levels
      @levels ||= catalog.fetch("levels").dup.freeze
    end

    def level?(level)
      levels.include?(level)
    end

    # Position in the seniority order, so callers can sort by level rather than
    # alphabetically. nil for an unknown level.
    def level_index(level)
      levels.index(level)
    end

    private

    def countries_by_code
      @countries_by_code ||= countries.index_by(&:code).freeze
    end

    def catalog
      @catalog ||= YAML.safe_load_file(PATH).freeze
    end
  end
end
