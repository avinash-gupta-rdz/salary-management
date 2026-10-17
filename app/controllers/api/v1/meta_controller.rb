module Api
  module V1
    # Option lists for filters and the employee form.
    class MetaController < ApplicationController
      def show
        render json: {
          data: {
            countries: Country.all.map(&:to_h),
            departments: Employee.distinct.order(:department).pluck(:department),
            job_titles: Employee.distinct.order(:job_title).pluck(:job_title),
            employment_types: Employee.employment_types.keys
          }
        }
      end
    end
  end
end
