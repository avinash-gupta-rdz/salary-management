class CreateSalaryChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :salary_changes do |t|
      t.references :employee, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.decimal :old_salary, null: false, precision: 12, scale: 2
      t.decimal :new_salary, null: false, precision: 12, scale: 2
      t.date :effective_date, null: false
      t.string :reason

      t.timestamps
    end

    add_index :salary_changes, [ :employee_id, :effective_date ]
    add_check_constraint :salary_changes, "old_salary > 0 AND new_salary > 0", name: "salary_change_amounts_positive"
  end
end
