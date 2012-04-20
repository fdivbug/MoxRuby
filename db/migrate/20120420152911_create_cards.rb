class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.string :name
      t.string :mana_cost
      t.string :types
      t.text :text

      t.timestamps
    end
  end
end
