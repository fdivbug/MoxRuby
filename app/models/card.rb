class Card < ActiveRecord::Base
  attr_accessible :mana_cost, :name, :text, :types
end
