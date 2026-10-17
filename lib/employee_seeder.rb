# Generates realistic, reproducible employees for demos and local development.
#
# Salaries come from a USD band per job title, scaled by a per-country pay
# factor and converted to the country's currency with the seeded exchange rates,
# so cross-country comparisons in the insights look believable.
class EmployeeSeeder
  BATCH_SIZE = 1_000

  # job title => annual salary band in USD (min, max). Titles come from Department.
  SALARY_BANDS = {
    "Software Engineer" => [ 60_000, 110_000 ],
    "Senior Software Engineer" => [ 90_000, 150_000 ],
    "Engineering Manager" => [ 120_000, 180_000 ],
    "QA Engineer" => [ 45_000, 80_000 ],
    "DevOps Engineer" => [ 70_000, 120_000 ],
    "Product Manager" => [ 80_000, 140_000 ],
    "Product Designer" => [ 60_000, 110_000 ],
    "Account Executive" => [ 50_000, 100_000 ],
    "Sales Manager" => [ 80_000, 140_000 ],
    "Marketing Specialist" => [ 45_000, 80_000 ],
    "Marketing Manager" => [ 75_000, 130_000 ],
    "Accountant" => [ 45_000, 80_000 ],
    "Financial Analyst" => [ 55_000, 95_000 ],
    "HR Generalist" => [ 40_000, 70_000 ],
    "Recruiter" => [ 45_000, 80_000 ],
    "Operations Analyst" => [ 45_000, 80_000 ],
    "Customer Support Specialist" => [ 30_000, 55_000 ]
  }.freeze

  # country code => [share of headcount, pay factor relative to the US]
  COUNTRY_PROFILES = {
    "IN" => [ 35, 0.30 ],
    "US" => [ 25, 1.00 ],
    "GB" => [ 12, 0.80 ],
    "DE" => [ 10, 0.80 ],
    "CA" => [ 10, 0.80 ],
    "SG" => [ 8, 0.85 ]
  }.freeze

  EMPLOYMENT_TYPES = { "full_time" => 85, "part_time" => 8, "contract" => 7 }.freeze

  FIRST_NAMES = %w[
    Aarav Priya Rohan Ananya Vikram Neha Arjun Kavya Rahul Sneha
    James Mary John Patricia Robert Jennifer Michael Linda David Sarah
    Oliver Amelia Harry Isla George Emily Lukas Mia Felix Hannah
    Wei Mei Jun Li Ethan Chloe Noah Emma Liam Sophia
  ].freeze

  LAST_NAMES = %w[
    Sharma Patel Iyer Reddy Gupta Nair Singh Mehta Rao Kapoor
    Smith Johnson Williams Brown Jones Miller Davis Wilson Taylor Clark
    Müller Schmidt Fischer Weber Wagner Tan Lim Ng Wong Chen
    Martin Roy Tremblay Gagnon Evans Walker Wright Hughes Green Hall
  ].freeze

  # Fixed instead of Date.current so the same seed always produces the same data.
  HIRE_DATE_RANGE = (Date.new(2015, 1, 1)..Date.new(2026, 6, 30)).freeze

  def initialize(count:, random: Random.new(42))
    @count = count
    @random = random
  end

  # Returns the number of employees inserted. Does nothing if employees already
  # exist, so re-running seeds never duplicates or overwrites HR's data.
  def call
    return 0 if Employee.exists?

    rates = ExchangeRate.pluck(:currency, :rate_to_usd).to_h

    (1..@count).each_slice(BATCH_SIZE) do |numbers|
      # insert_all skips validations; attributes are built to satisfy them and
      # the database constraints still apply.
      Employee.insert_all!(numbers.map { |number| attributes_for(number, rates) })
    end

    @count
  end

  private

  def attributes_for(number, rates)
    first_name = FIRST_NAMES.sample(random: @random)
    last_name = LAST_NAMES.sample(random: @random)
    department = Department.all.sample(random: @random)
    job_title = department.job_titles.sample(random: @random)
    band_min, band_max = SALARY_BANDS.fetch(job_title)
    country = Country.find(weighted_pick(COUNTRY_PROFILES.transform_values(&:first)))
    pay_factor = COUNTRY_PROFILES.fetch(country.code).last

    {
      full_name: "#{first_name} #{last_name}",
      # Names like Müller are fine, but email addresses must be ASCII to pass validation.
      email: I18n.transliterate("#{first_name}.#{last_name}.#{number}@acme.test").downcase,
      job_title: job_title,
      department: department.name,
      country_code: country.code,
      currency: country.currency,
      annual_salary: local_salary(band_min, band_max, pay_factor, rates.fetch(country.currency)),
      employment_type: weighted_pick(EMPLOYMENT_TYPES),
      hire_date: @random.rand(HIRE_DATE_RANGE)
    }
  end

  # Rounded to the nearest 1,000 in local currency, like real salary offers.
  def local_salary(band_min, band_max, pay_factor, rate_to_usd)
    usd = @random.rand(band_min..band_max) * pay_factor
    ((usd / rate_to_usd) / 1_000).round * 1_000
  end

  def weighted_pick(weights)
    target = @random.rand(weights.values.sum)
    weights.each do |value, weight|
      return value if target < weight

      target -= weight
    end
  end
end
