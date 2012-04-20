class CreateRarities < ActiveRecord::Migration
  def change
    create_table :rarities do |t|
      t.string :name
      t.string :abbreviation
    end

    Rarity.create(:name => "Common", :abbreviation => "C")
    Rarity.create(:name => "Uncommon", :abbreviation => "U")
    Rarity.create(:name => "Rare", :abbreviation => "R")
    Rarity.create(:name => "Mythic Rare", :abbreviation => "M")
    Rarity.create(:name => "Basic Land", :abbreviation => "L")
  end
end
