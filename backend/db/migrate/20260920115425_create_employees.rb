class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      # ISO 3166-1 alpha-2. The currency is derived from this, not stored.
      t.string :country_code, limit: 2, null: false
      t.string :department, null: false
      t.string :job_title, null: false
      t.string :level, null: false
      # Whole units of the country's currency: annual base gross pay.
      t.integer :annual_salary, null: false
      t.date :hire_date, null: false

      t.timestamps
    end

    add_index :employees, :employee_code, unique: true
    # Emails are stored downcased; the functional index enforces uniqueness even
    # if a row ever slips in with different casing.
    add_index :employees, "LOWER(email)", unique: true, name: "index_employees_on_lower_email"

    # One index per filter column: the list and the analytics filter and group
    # by exactly these.
    add_index :employees, :country_code
    add_index :employees, :department
    add_index :employees, :job_title
    add_index :employees, :level
  end
end
