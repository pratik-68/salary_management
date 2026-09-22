# The JSON shape of one employee.
#
# It carries the country's name and currency alongside the country code even
# though neither is stored on the record: every salary the UI shows has to be
# labelled with its currency, and making the client join each row against the
# catalog to find it would be an easy thing to forget.
class EmployeeSerializer
  def self.one(employee)
    new(employee).as_json
  end

  def self.many(employees)
    employees.map { |employee| new(employee).as_json }
  end

  def initialize(employee)
    @employee = employee
  end

  def as_json(*)
    {
      id: employee.id,
      employee_code: employee.employee_code,
      first_name: employee.first_name,
      last_name: employee.last_name,
      full_name: employee.full_name,
      email: employee.email,
      country_code: employee.country_code,
      country_name: country&.name,
      currency: country&.currency,
      department: employee.department,
      job_title: employee.job_title,
      level: employee.level,
      annual_salary: employee.annual_salary,
      hire_date: employee.hire_date&.iso8601
    }
  end

  private

  attr_reader :employee

  def country
    ReferenceData.country(employee.country_code)
  end
end
