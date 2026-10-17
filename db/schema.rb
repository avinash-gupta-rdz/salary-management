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

ActiveRecord::Schema[8.1].define(version: 2026_10_17_150358) do
  create_table "employees", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "job_title", null: false
    t.string "department", null: false
    t.string "country_code", limit: 2, null: false
    t.string "currency", limit: 3, null: false
    t.decimal "annual_salary", precision: 12, scale: 2, null: false
    t.string "employment_type", null: false
    t.date "hire_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "job_title"], name: "index_employees_on_country_code_and_job_title"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.check_constraint "annual_salary > 0", name: "annual_salary_positive"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "currency", limit: 3, null: false
    t.decimal "rate_to_usd", precision: 18, scale: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency"], name: "index_exchange_rates_on_currency", unique: true
    t.check_constraint "rate_to_usd > 0", name: "rate_to_usd_positive"
  end

  create_table "salary_changes", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.decimal "old_salary", precision: 12, scale: 2, null: false
    t.decimal "new_salary", precision: 12, scale: 2, null: false
    t.date "effective_date", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "old_currency", limit: 3, null: false
    t.string "new_currency", limit: 3, null: false
    t.index ["employee_id", "effective_date"], name: "index_salary_changes_on_employee_id_and_effective_date"
    t.check_constraint "old_salary > 0 AND new_salary > 0", name: "salary_change_amounts_positive"
  end

  add_foreign_key "salary_changes", "employees", on_delete: :cascade
end
