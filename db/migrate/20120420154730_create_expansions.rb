class CreateExpansions < ActiveRecord::Migration
  def change
    create_table :expansions do |t|
      t.string :name
      t.string :code
      t.date :release_date
      t.string :border
      t.string :scg_name
      t.string :scg_number

      t.timestamps
    end
  end
end
