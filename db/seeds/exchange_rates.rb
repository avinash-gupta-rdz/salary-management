# Fixed, approximate rates as of 2026 (units of USD per 1 unit of currency).
# Kept fixed on purpose so reports and tests are reproducible.
rates = {
  "USD" => "1.0",
  "INR" => "0.012",
  "GBP" => "1.27",
  "EUR" => "1.08",
  "SGD" => "0.74",
  "CAD" => "0.73"
}

ExchangeRate.upsert_all(
  rates.map { |currency, rate| { currency: currency, rate_to_usd: rate } },
  unique_by: :currency
)
