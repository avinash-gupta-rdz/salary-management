require "rails_helper"

RSpec.describe Department do
  it "finds a department with its job titles" do
    expect(described_class.find("Sales").job_titles).to eq([ "Account Executive", "Sales Manager" ])
  end

  it "returns nil for an unknown department" do
    expect(described_class.find("Legal")).to be_nil
  end

  it "never lists the same job title under two departments" do
    titles = described_class.job_titles

    expect(titles).to eq(titles.uniq)
  end
end
