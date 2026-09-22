# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_20_115425) do
  create_table "employees", force: :cascade do |t|
    t.integer "annual_salary", null: false
    t.string "country_code", limit: 2, null: false
    t.datetime "created_at", null: false
    t.string "department", null: false
    t.string "email", null: false
    t.string "employee_code", null: false
    t.string "first_name", null: false
    t.date "hire_date", null: false
    t.string "job_title", null: false
    t.string "last_name", null: false
    t.string "level", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(email)", name: "index_employees_on_lower_email", unique: true
    t.index ["country_code"], name: "index_employees_on_country_code"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.index ["level"], name: "index_employees_on_level"
  end
end
