class CreateDecks < ActiveRecord::Migration
  def change
    create_table :decks, :id => false, :primary_key => "uuid" do |t|
      t.string :uuid, :limit => 36, :primary => true
      t.integer :user_id
      t.string :name

      t.timestamps
    end

    create_table :cards_decks do |t|
      t.integer :card_id
      t.integer :deck_id
      t.integer :count
      t.string :section # One of "main", "sideboard", "command", "plane", or "scheme"
    end
  end
end
