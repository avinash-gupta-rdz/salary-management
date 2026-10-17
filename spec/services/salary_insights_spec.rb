require "rails_helper"

RSpec.describe SalaryInsights do
  subject(:insights) { described_class.new }

  before { load Rails.root.join("db/seeds/exchange_rates.rb") } # INR rate is 0.012

  # Small known dataset, USD equivalents in comments.
  def create_dataset
    create(:employee, country_code: "IN", department: "Engineering", job_title: "Software Engineer", annual_salary: 1_000_000) # 12,000
    create(:employee, country_code: "IN", department: "Engineering", job_title: "Software Engineer", annual_salary: 2_000_000) # 24,000
    create(:employee, country_code: "IN", department: "Sales", job_title: "Account Executive", annual_salary: 3_000_000)       # 36,000
    create(:employee, country_code: "US", department: "Engineering", job_title: "Software Engineer", annual_salary: 100_000)
    create(:employee, country_code: "US", department: "Sales", job_title: "Account Executive", annual_salary: 50_000)
  end

  describe "#summary" do
    it "reports org-wide figures in USD" do
      create_dataset

      expect(insights.summary).to eq(
        headcount: 5,
        total_payroll_usd: 222_000.0,
        average_salary_usd: 44_400.0,
        median_salary_usd: 36_000.0,
        countries: 2,
        departments: 2
      )
    end

    it "handles an empty org" do
      expect(insights.summary).to include(headcount: 0, total_payroll_usd: nil, median_salary_usd: nil)
    end

    it "fails loudly when a currency has no exchange rate" do
      ExchangeRate.where(currency: "GBP").delete_all
      create(:employee, country_code: "GB")

      expect { insights.summary }.to raise_error(SalaryInsights::MissingExchangeRate, /GBP/)
    end
  end

  describe "#by_country" do
    it "reports local-currency stats with USD figures, largest country first" do
      create_dataset

      india, us = insights.by_country

      expect(india).to eq(
        country_code: "IN", country_name: "India", currency: "INR", headcount: 3,
        min_salary: 1_000_000.0, max_salary: 3_000_000.0, average_salary: 2_000_000.0,
        median_salary: 2_000_000.0, total_payroll: 6_000_000.0,
        average_salary_usd: 24_000.0, total_payroll_usd: 72_000.0
      )
      expect(us).to include(country_code: "US", headcount: 2, median_salary: 75_000.0, total_payroll_usd: 150_000.0)
    end
  end

  describe "#by_job_title" do
    it "uses the country's currency when scoped to a country" do
      create_dataset

      result = insights.by_job_title(country_code: "IN")

      expect(result[:currency]).to eq("INR")
      expect(result[:rows]).to eq([
        { job_title: "Account Executive", headcount: 1, min_salary: 3_000_000.0, max_salary: 3_000_000.0, average_salary: 3_000_000.0, median_salary: 3_000_000.0 },
        { job_title: "Software Engineer", headcount: 2, min_salary: 1_000_000.0, max_salary: 2_000_000.0, average_salary: 1_500_000.0, median_salary: 1_500_000.0 }
      ])
    end
  end

  describe "#by_department" do
    it "uses USD across countries, highest average first" do
      create_dataset

      result = insights.by_department

      expect(result[:currency]).to eq("USD")
      expect(result[:rows]).to eq([
        { department: "Engineering", headcount: 3, min_salary: 12_000.0, max_salary: 100_000.0, average_salary: 45_333.33, median_salary: 24_000.0 },
        { department: "Sales", headcount: 2, min_salary: 36_000.0, max_salary: 50_000.0, average_salary: 43_000.0, median_salary: 43_000.0 }
      ])
    end
  end

  describe "#distribution" do
    it "buckets salaries with a round bucket width, including empty buckets" do
      create_dataset

      result = insights.distribution(country_code: "US")

      expect(result[:currency]).to eq("USD")
      expect(result[:buckets].first).to eq(from: 50_000, to: 55_000, count: 1)
      expect(result[:buckets].last).to eq(from: 100_000, to: 105_000, count: 1)
      expect(result[:buckets].sum { |bucket| bucket[:count] }).to eq(2)
    end

    it "can narrow to a job title" do
      create_dataset

      result = insights.distribution(country_code: "IN", job_title: "Software Engineer")

      expect(result[:buckets].sum { |bucket| bucket[:count] }).to eq(2)
    end

    it "returns no buckets when nobody matches" do
      expect(insights.distribution(country_code: "SG")).to eq(currency: "SGD", buckets: [])
    end
  end
end
