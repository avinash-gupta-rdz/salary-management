require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  subject(:rate) { build(:exchange_rate) }

  it "is valid with valid attributes" do
    expect(rate).to be_valid
  end

  describe "currency" do
    it "is required" do
      rate.currency = nil

      expect(rate).not_to be_valid
      expect(rate.errors[:currency]).to include("can't be blank")
    end

    it "is stored upcased" do
      rate.currency = " gbp "

      expect(rate.currency).to eq("GBP")
    end

    it "must be a 3-letter code" do
      rate.currency = "RS"

      expect(rate).not_to be_valid
      expect(rate.errors[:currency]).to include("must be a 3-letter ISO code")
    end

    it "must be unique" do
      create(:exchange_rate, currency: "INR")

      expect(rate).not_to be_valid
      expect(rate.errors[:currency]).to include("has already been taken")
    end
  end

  describe "rate_to_usd" do
    it "must be greater than zero" do
      rate.rate_to_usd = 0

      expect(rate).not_to be_valid
      expect(rate.errors[:rate_to_usd]).to include("must be greater than 0")
    end

    it "is enforced by a database check constraint" do
      rate.save!

      expect { rate.update_column(:rate_to_usd, 0) }
        .to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint failed/)
    end
  end

  describe ".to_usd" do
    before { create(:exchange_rate, currency: "GBP", rate_to_usd: "1.27") }

    it "converts an amount to USD rounded to cents" do
      expect(described_class.to_usd(BigDecimal("55555.55"), "GBP")).to eq(BigDecimal("70555.55"))
    end

    it "raises when the currency has no rate" do
      expect { described_class.to_usd(100, "JPY") }.to raise_error(ExchangeRate::Missing, "No exchange rate for JPY")
    end
  end
end
