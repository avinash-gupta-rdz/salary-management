# Fixed conversion rates to USD, the reporting currency for cross-country comparisons.
class ExchangeRate < ApplicationRecord
  # Raised wherever a USD figure is needed but the currency has no rate, so a
  # missing rate is always an error rather than a silently wrong number.
  class Missing < StandardError
    def initialize(currencies)
      super("No exchange rate for #{Array(currencies).join(', ')}")
    end
  end

  normalizes :currency, with: ->(value) { value.strip.upcase }

  validates :currency, presence: true,
                       uniqueness: true,
                       format: { with: /\A[A-Z]{3}\z/, message: "must be a 3-letter ISO code" }
  validates :rate_to_usd, presence: true, numericality: { greater_than: 0 }

  def self.to_usd(amount, currency)
    rate = find_by(currency: currency) or raise Missing, currency
    (amount * rate.rate_to_usd).round(2)
  end
end
