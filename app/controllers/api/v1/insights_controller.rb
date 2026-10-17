module Api
  module V1
    class InsightsController < ApplicationController
      before_action :validate_country_code, except: %i[summary by_country]

      def summary
        render json: { data: insights.summary }
      end

      def by_country
        render json: { data: insights.by_country }
      end

      def by_job_title
        render json: { data: insights.by_job_title(country_code: params[:country_code]) }
      end

      def by_department
        render json: { data: insights.by_department(country_code: params[:country_code]) }
      end

      def distribution
        render json: { data: insights.distribution(country_code: params[:country_code], job_title: params[:job_title]) }
      end

      private

      def insights
        SalaryInsights.new
      end

      def validate_country_code
        return if params[:country_code].blank? || Country.codes.include?(params[:country_code])

        render json: { error: "Unsupported country_code" }, status: :bad_request
      end
    end
  end
end
