class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :currency, null: false, limit: 3
      t.decimal :rate_to_usd, null: false, precision: 18, scale: 8

      t.timestamps
    end

    add_index :exchange_rates, :currency, unique: true
    add_check_constraint :exchange_rates, "rate_to_usd > 0", name: "rate_to_usd_positive"
  end
end
