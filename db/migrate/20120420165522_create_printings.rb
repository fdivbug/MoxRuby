class CreatePrintings < ActiveRecord::Migration
  def change
    create_table :printings do |t|
      t.integer :card_id
      t.integer :expansion_id
      t.integer :artist_id
      t.integer :rarity_id
      t.integer :number
      t.integer :multiverse_id
    end
  end
end
