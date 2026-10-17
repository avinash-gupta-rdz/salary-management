# Fixed conversion rates to USD, the reporting currency for cross-country comparisons.
class ExchangeRate < ApplicationRecord
  normalizes :currency, with: ->(value) { value.strip.upcase }

  validates :currency, presence: true,
                       uniqueness: true,
                       format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO code" }
  validates :rate_to_usd, presence: true, numericality: { greater_than: 0 }

  # Raises ActiveRecord::RecordNotFound when the currency has no rate, so a
  # missing rate surfaces as an error instead of a silently wrong total.
  def self.to_usd(amount, currency)
    (amount * find_by!(currency: currency).rate_to_usd).round(2)
  end
end
