module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: %i[show update destroy]

      def index
        result = EmployeeSearch.new(search_params).call

        render json: {
          data: result.records.map { |employee| EmployeeSerializer.new(employee) },
          meta: { page: result.page, per_page: result.per_page, total: result.total, total_pages: result.total_pages }
        }
      end

      def show
        render json: { data: EmployeeSerializer.new(@employee) }
      end

      def create
        employee = Employee.new(employee_params)

        if employee.save
          render json: { data: EmployeeSerializer.new(employee) }, status: :created
        else
          render_validation_errors(employee)
        end
      end

      def update
        if @employee.update(employee_params)
          render json: { data: EmployeeSerializer.new(@employee) }
        else
          render_validation_errors(@employee)
        end
      end

      def destroy
        @employee.destroy!
        head :no_content
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      # currency is deliberately not permitted: it is derived from country_code.
      def employee_params
        params.expect(employee: %i[
          full_name email job_title department country_code annual_salary
          employment_type hire_date salary_change_reason salary_effective_date
        ])
      end

      def search_params
        params.permit(:q, :page, :per_page, :sort, :direction, *EmployeeSearch::FILTERS)
      end

      def render_validation_errors(employee)
        render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
