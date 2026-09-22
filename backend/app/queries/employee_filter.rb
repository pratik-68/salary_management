# Turns request params into an employee scope.
#
# Both the employee list and the analytics build their scope here, so
# "department=Sales" picks out exactly the same people in a table row as it
# does in a median. The filters are written and tested once.
#
# Two rules are enforced rather than left to the caller:
#
# - **Unknown values are rejected, not ignored.** Dropping a filter the caller
#   asked for would quietly show more people than they think they are looking
#   at, and on salary data that is the expensive kind of wrong.
# - **Sorting by salary needs a country.** Salaries are never converted, so a
#   list ordered by salary across currencies would rank 90,000 USD below
#   2,400,000 INR. Ordering is only meaningful inside one country.
class EmployeeFilter
  # Allow-list: anything not here is a 400 rather than SQL we did not intend.
  SORT_COLUMNS = %w[
    employee_code first_name last_name email country_code
    department job_title level annual_salary hire_date
  ].freeze
  DEFAULT_SORT = "employee_code".freeze

  DIRECTIONS = %w[asc desc].freeze
  DEFAULT_DIRECTION = "asc".freeze

  # Sorts that only mean something within a single currency.
  COUNTRY_SCOPED_SORTS = %w[annual_salary].freeze

  # Matches the search term against the parts of a record the HR Manager knows
  # someone by. The concatenation is there so "Ada Lovelace" finds Ada, which
  # neither first_name nor last_name alone would do.
  SEARCH_SQL = <<~SQL.squish.freeze
    employees.first_name LIKE :term
    OR employees.last_name LIKE :term
    OR employees.email LIKE :term
    OR employees.employee_code LIKE :term
    OR (employees.first_name || ' ' || employees.last_name) LIKE :term
  SQL

  attr_reader :query, :country_code, :department, :job_title, :level, :sort, :direction

  # @param params [ActionController::Parameters, Hash] the request params;
  #   unrelated keys are ignored.
  def initialize(params = {})
    attrs = normalize(params)

    @query        = presence(attrs[:q])
    @country_code = presence(attrs[:country])&.upcase
    @department   = presence(attrs[:department])
    @job_title    = presence(attrs[:job_title])
    @level        = presence(attrs[:level])&.upcase
    @sort         = presence(attrs[:sort]) || DEFAULT_SORT
    @direction    = presence(attrs[:direction])&.downcase || DEFAULT_DIRECTION

    validate!
  end

  # Filtered but unordered: what the analytics aggregates over.
  def scope(relation = Employee.all)
    relation = relation.where(country_code: country_code) if country_code
    relation = relation.where(department: department)     if department
    relation = relation.where(job_title: job_title)       if job_title
    relation = relation.where(level: level)               if level
    relation = search(relation)                           if query
    relation
  end

  # Filtered and ordered. The id tiebreak keeps paging stable: without it two
  # people sharing a salary can swap places between page 1 and page 2, so a row
  # is shown twice and another never at all.
  def sorted_scope(relation = Employee.all)
    scope(relation).order(sort => direction, id: :asc)
  end

  # True when the scope is confined to one country, and so to one currency.
  def single_country?
    country_code.present?
  end

  private

  # Accepts controller params or a plain hash, with string or symbol keys.
  def normalize(params)
    hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    hash.symbolize_keys
  end

  def presence(value)
    value.to_s.strip.presence
  end

  def search(relation)
    # sanitize_sql_like escapes % and _ so a search for "a_b" looks for that
    # literal string rather than matching any character.
    relation.where(SEARCH_SQL, term: "%#{Employee.sanitize_sql_like(query)}%")
  end

  def validate!
    validate_sort!
    validate_catalog_values!
  end

  def validate_sort!
    unless SORT_COLUMNS.include?(sort)
      raise InvalidParams.new("'#{sort}' is not a sortable column.", code: "invalid_sort")
    end

    unless DIRECTIONS.include?(direction)
      raise InvalidParams.new("Sort direction must be asc or desc.", code: "invalid_direction")
    end

    return unless COUNTRY_SCOPED_SORTS.include?(sort) && country_code.blank?

    raise InvalidParams.new(
      "Sorting by salary needs a country filter, because salaries are never converted between currencies.",
      code: "country_required"
    )
  end

  def validate_catalog_values!
    reject_unknown(:country, country_code) { ReferenceData.country?(country_code) }
    reject_unknown(:department, department) { ReferenceData.department?(department) }
    reject_unknown(:level, level) { ReferenceData.level?(level) }
    reject_unknown(:job_title, job_title) { ReferenceData.job_titles.include?(job_title) }
  end

  def reject_unknown(name, value)
    return if value.blank? || yield

    raise InvalidParams.new("'#{value}' is not a known #{name.to_s.humanize.downcase}.", code: "invalid_#{name}")
  end
end
