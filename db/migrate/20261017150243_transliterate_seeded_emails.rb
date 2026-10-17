# Seeded employees with accented names (e.g. Müller) got emails like
# noah.müller.96@acme.test, which fail email validation, so they couldn't be
# edited. Rewrites only seeded (@acme.test) addresses to ASCII; the numeric
# suffix keeps them unique.
class TransliterateSeededEmails < ActiveRecord::Migration[8.1]
  class Employee < ActiveRecord::Base
    self.table_name = "employees"
  end

  def up
    Employee.where("email LIKE ?", "%@acme.test").find_each do |employee|
      ascii = I18n.transliterate(employee.email).downcase
      employee.update_columns(email: ascii) if ascii != employee.email
    end
  end

  def down
    # Not reversible: the original non-ASCII addresses were invalid anyway.
  end
end
