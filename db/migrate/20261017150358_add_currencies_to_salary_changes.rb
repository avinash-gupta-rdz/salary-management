# A salary change can now cross currencies (the employee moved country), so each
# side of the change records its own currency. Existing rows predate country
# changes being recorded, so both sides are the employee's current currency.
class AddCurrenciesToSalaryChanges < ActiveRecord::Migration[8.1]
  def up
    add_column :salary_changes, :old_currency, :string, limit: 3
    add_column :salary_changes, :new_currency, :string, limit: 3

    execute <<~SQL
      UPDATE salary_changes
      SET old_currency = (SELECT currency FROM employees WHERE employees.id = salary_changes.employee_id),
          new_currency = (SELECT currency FROM employees WHERE employees.id = salary_changes.employee_id)
    SQL

    change_column_null :salary_changes, :old_currency, false
    change_column_null :salary_changes, :new_currency, false
  end

  def down
    remove_column :salary_changes, :old_currency
    remove_column :salary_changes, :new_currency
  end
end
