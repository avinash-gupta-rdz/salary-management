# Countries ACME operates in. Kept in code rather than a table because the list
# changes rarely and each country maps to exactly one payroll currency.
class Country < Data.define(:code, :name, :currency)
  ALL = [
    new(code: "IN", name: "India", currency: "INR"),
    new(code: "US", name: "United States", currency: "USD"),
    new(code: "GB", name: "United Kingdom", currency: "GBP"),
    new(code: "DE", name: "Germany", currency: "EUR"),
    new(code: "SG", name: "Singapore", currency: "SGD"),
    new(code: "CA", name: "Canada", currency: "CAD")
  ].freeze

  def self.all
    ALL
  end

  def self.find(code)
    ALL.find { |country| country.code == code }
  end

  def self.codes
    ALL.map(&:code)
  end

  def self.currencies
    ALL.map(&:currency).uniq
  end
end
