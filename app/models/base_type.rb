class BaseType < ActiveRecord::Base
  set_table_name "types"

  attr_accessible :name, :type

  has_and_belongs_to_many :cards, :join_table => "cards_types", :foreign_key => "type_id"

  def to_s
    name
  end
end
