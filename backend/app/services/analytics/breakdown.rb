module Analytics
  # Pay statistics for one slice of the workforce, grouped by country,
  # department, job title or level.
  #
  # It answers both insight views from one place: group by country to see what
  # each country costs, or pick a country and group by something inside it to
  # see how pay varies there.
  #
  # The currency rule is enforced here rather than left to the caller. Every
  # row's figures come from employees of exactly one country and are labelled
  # with that country's currency, so nothing is ever converted or mixed:
  #
  # - `group_by=country` gives one row per country, each in its own currency.
  # - Any other grouping needs a country filter, because "the median for
  #   Engineering" across eight currencies is not a number that means anything.
  #
  # Filters come from EmployeeFilter, so narrowing a breakdown and narrowing the
  # employee list pick out the same people.
  class Breakdown
    # group_by value -> the column it groups on, and the catalog list that puts
    # the rows in a sensible order (seniority for levels, not alphabetical).
    GROUPS = {
      "country" => { column: :country_code, order: -> { ReferenceData.country_codes } },
      "department" => { column: :department, order: -> { ReferenceData.departments } },
      "job_title" => { column: :job_title, order: -> { ReferenceData.job_titles } },
      "level" => { column: :level, order: -> { ReferenceData.levels } }
    }.freeze

    # One group's pay, all of it in `currency`. `median` and `average` are kept
    # exact here; rounding for display happens in the serializer.
    Row = Data.define(:group, :country_code, :country_name, :currency,
      :headcount, :min, :median, :average, :max, :total)

    attr_reader :group_by, :filter

    def initialize(params = {})
      # Accepts controller params or a plain hash, with string or symbol keys.
      attrs = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      @group_by = attrs.symbolize_keys[:group_by].to_s.strip.presence
      @filter = EmployeeFilter.new(params)

      validate!
    end

    def rows
      @rows ||= build_rows
    end

    # Total people in the breakdown. It is the one figure that can be summed
    # across countries, because headcount has no currency.
    def headcount
      rows.sum(&:headcount)
    end

    # The currency every row shares, or nil when the rows span countries and
    # therefore several currencies.
    def currency
      ReferenceData.currency_for(country_code) if country_code
    end

    def country_code
      filter.country_code
    end

    private

    def group
      GROUPS.fetch(group_by)
    end

    def column
      group[:column]
    end

    def validate!
      unless GROUPS.key?(group_by)
        raise InvalidParams.new(
          "group_by must be one of: #{GROUPS.keys.join(', ')}.",
          code: "invalid_group_by"
        )
      end

      return if group_by == "country" || filter.single_country?

      raise InvalidParams.new(
        "Grouping by #{group_by} needs a country filter, because salaries are never converted between currencies.",
        code: "country_required"
      )
    end

    # Two passes over the same scope: the database does the counting, the
    # extremes and the sum, which is what it is good at, and Ruby does the one
    # thing SQLite cannot. At 10k rows both are a few milliseconds.
    def build_rows
      scope = filter.scope
      medians = medians_by_group(scope)

      aggregates(scope).map { |values| row_for(values, medians) }.sort_by { |row| position(row.group) }
    end

    def aggregates(scope)
      scope.group(column).pluck(
        column,
        Arel.sql("COUNT(*)"),
        Arel.sql("MIN(employees.annual_salary)"),
        Arel.sql("MAX(employees.annual_salary)"),
        Arel.sql("SUM(employees.annual_salary)")
      )
    end

    def medians_by_group(scope)
      scope.pluck(column, :annual_salary)
        .group_by(&:first)
        .transform_values { |pairs| Median.of(pairs.map(&:last)) }
    end

    def row_for(values, medians)
      value, headcount, minimum, maximum, total = values
      country = ReferenceData.country(group_by == "country" ? value : country_code)

      Row.new(
        group: value,
        country_code: country&.code,
        country_name: country&.name,
        currency: country&.currency,
        headcount: headcount,
        min: minimum,
        median: medians[value],
        # Exact division: the average of whole salaries is rarely a whole
        # number, and rounding it here would hide which way it was rounded.
        average: Rational(total, headcount),
        max: maximum,
        total: total
      )
    end

    # Where this value sits in the catalog. Anything the catalog does not know
    # about sorts last rather than disappearing.
    def position(value)
      order = group[:order].call
      order.index(value) || order.length
    end
  end
end
