require "rails_helper"

RSpec.describe Country do
  describe ".find" do
    it "returns the country for a known code" do
      country = described_class.find("DE")

      expect(country.name).to eq("Germany")
      expect(country.currency).to eq("EUR")
    end

    it "returns nil for an unknown code" do
      expect(described_class.find("FR")).to be_nil
    end
  end

  it "lists the six countries ACME operates in" do
    expect(described_class.codes).to contain_exactly("IN", "US", "GB", "DE", "SG", "CA")
  end

  it "lists each payroll currency once" do
    expect(described_class.currencies).to contain_exactly("INR", "USD", "GBP", "EUR", "SGD", "CAD")
  end
end
