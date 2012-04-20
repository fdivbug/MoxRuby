class CreateTypes < ActiveRecord::Migration
  def change
    create_table :types do |t|
      t.string :name
      t.string :type
    end

    create_table :cards_types do |t|
      t.integer :card_id
      t.integer :type_id
    end
  end
end
