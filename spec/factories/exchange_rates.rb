FactoryBot.define do
  factory :exchange_rate do
    currency { "INR" }
    rate_to_usd { "0.012" }
  end
end
