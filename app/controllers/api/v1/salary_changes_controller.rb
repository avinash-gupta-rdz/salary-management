module Api
  module V1
    class SalaryChangesController < ApplicationController
      def index
        employee = Employee.find(params[:employee_id])
        changes = employee.salary_changes.latest_first

        render json: {
          data: changes.map do |change|
            {
              id: change.id,
              old_salary: change.old_salary.to_f,
              old_currency: change.old_currency,
              new_salary: change.new_salary.to_f,
              new_currency: change.new_currency,
              effective_date: change.effective_date,
              reason: change.reason,
              created_at: change.created_at
            }
          end
        }
      end
    end
  end
end
