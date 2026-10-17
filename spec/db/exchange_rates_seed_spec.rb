require "rails_helper"

RSpec.describe "exchange rates seed" do
  def run_seed
    load Rails.root.join("db/seeds/exchange_rates.rb")
  end

  it "has a rate for every country's currency" do
    run_seed

    expect(ExchangeRate.pluck(:currency)).to include(*Country.currencies)
  end

  it "can be run more than once" do
    2.times { run_seed }

    expect(ExchangeRate.count).to eq(Country.currencies.size)
  end
end
