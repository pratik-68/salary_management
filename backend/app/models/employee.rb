# An employee record: who they are, where they work, and what they are paid.
#
# Salary is annual base gross pay as a whole-number amount in the currency of
# the employee's country (see ReferenceData). It is never converted, so every
# figure derived from it belongs to exactly one country.
class Employee < ApplicationRecord
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :employee_code, with: ->(code) { code.strip.upcase }
  normalizes :first_name, :last_name, with: ->(name) { name.strip }
  normalizes :country_code, with: ->(code) { code.strip.upcase }

  validates :employee_code, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email,
    presence: true,
    format: { with: EMAIL_FORMAT, allow_blank: true },
    uniqueness: { case_sensitive: false }
  validates :country_code,
    presence: true,
    inclusion: { in: ->(_) { ReferenceData.country_codes }, allow_blank: true, message: "is not a supported country" }
  validates :department,
    presence: true,
    inclusion: { in: ->(_) { ReferenceData.departments }, allow_blank: true, message: "is not a known department" }
  validates :level,
    presence: true,
    inclusion: { in: ->(_) { ReferenceData.levels }, allow_blank: true, message: "is not a known level" }
  validates :job_title, presence: true
  validates :annual_salary, numericality: { only_integer: true, greater_than: 0 }
  validates :hire_date, presence: true

  validate :job_title_belongs_to_department
  validate :hire_date_is_not_in_the_future

  # The currency this employee's salary is expressed in, e.g. "INR".
  def currency
    ReferenceData.currency_for(country_code)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  # A title is only valid inside its own department: an "Accountant" in
  # Engineering is a data-entry mistake, and it would split the analytics.
  def job_title_belongs_to_department
    return if job_title.blank? || department.blank?
    return unless ReferenceData.department?(department)
    return if ReferenceData.job_titles_for(department).include?(job_title)

    errors.add(:job_title, "is not a job title in #{department}")
  end

  def hire_date_is_not_in_the_future
    return if hire_date.blank? || hire_date <= Date.current

    errors.add(:hire_date, "can't be in the future")
  end
end
