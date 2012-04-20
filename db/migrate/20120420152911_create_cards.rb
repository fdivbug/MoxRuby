class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.string :name
      t.string :mana_cost
      t.text :text
      t.string :power
      t.string :toughness
      t.string :face
      t.string :color_indicator
      t.integer :transforms_into_id # This is a card ID.

      t.timestamps
    end
  end
end
