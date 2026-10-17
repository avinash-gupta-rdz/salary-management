module Api
  module V1
    # Option lists for filters and the employee form.
    class MetaController < ApplicationController
      def show
        render json: {
          data: {
            countries: Country.all.map(&:to_h),
            departments: Department.names,
            job_titles: Department.job_titles.sort,
            job_titles_by_department: Department.all.to_h { |department| [ department.name, department.job_titles ] },
            employment_types: Employee.employment_types.keys
          }
        }
      end
    end
  end
end
