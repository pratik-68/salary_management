# Loads the HR Manager's login and the demo dataset: 10,000 employees, the
# same ones on every run.
#
#   bin/rails db:seed
#   SEED_EMPLOYEE_COUNT=200 bin/rails db:seed   # a smaller set to work against
#
# Idempotent by replacement: the table is emptied first, so seeding twice
# leaves the same 10,000 rows rather than 20,000.

count = Integer(ENV.fetch("SEED_EMPLOYEE_COUNT", Seeds::EmployeeGenerator::DEFAULT_COUNT))
seed = Integer(ENV.fetch("SEED_RANDOM_SEED", Seeds::EmployeeGenerator::DEFAULT_SEED))
batch_size = 1_000

generator = Seeds::EmployeeGenerator.new(count: count, seed: seed)

Employee.transaction do
  Employee.delete_all

  # insert_all in batches rather than create! per row: one INSERT per 1,000
  # employees instead of 10,000 round trips, which is the difference between
  # seconds and minutes. Validations are covered by the generator's spec.
  generator.each_slice(batch_size) { |batch| Employee.insert_all!(batch) }
end

puts "Seeded #{Employee.count} employees (seed: #{seed})"

# The single HR Manager account. Credentials come from the environment so that
# a real deployment never inherits a password from source control; the
# development defaults below are documented in the README and are why the app
# is not deployed as-is.
email = ENV.fetch("HR_MANAGER_EMAIL", "hr@example.com")
password = ENV.fetch("HR_MANAGER_PASSWORD", "password123")

# find_or_initialize rather than create: re-seeding resets the password to
# whatever the environment currently says, and never leaves two accounts.
user = User.find_or_initialize_by(email_address: email)
user.password = password
user.save!

puts "Seeded HR Manager #{user.email_address}"
