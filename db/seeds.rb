# Idempotent: safe to run more than once.
load Rails.root.join("db/seeds/exchange_rates.rb")

inserted = EmployeeSeeder.new(count: 10_000).call
puts(inserted.zero? ? "Employees already present, skipped seeding." : "Seeded #{inserted} employees.")
