class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :job_title, null: false
      t.string :department, null: false
      t.string :country_code, null: false, limit: 2
      t.string :currency, null: false, limit: 3
      t.decimal :annual_salary, null: false, precision: 12, scale: 2
      t.string :employment_type, null: false
      t.date :hire_date, null: false

      t.timestamps
    end

    add_index :employees, :email, unique: true
    add_index :employees, :department
    add_index :employees, [ :country_code, :job_title ]
    add_index :employees, :job_title

    add_check_constraint :employees, "annual_salary > 0", name: "annual_salary_positive"
  end
end
