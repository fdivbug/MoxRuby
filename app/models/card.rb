class Card < ActiveRecord::Base
  attr_accessible :mana_cost, :name, :text, :power, :toughness

  validates_uniqueness_of :name

  has_many :printings
  has_and_belongs_to_many :types
  has_and_belongs_to_many :subtypes, :join_table => "cards_types", :association_foreign_key => "type_id"
  has_and_belongs_to_many :supertypes, :join_table => "cards_types", :association_foreign_key => "type_id"

  def converted_mana_cost
    cmc = 0
    md = mana_cost.match(/([0-9]+)/)
    if md
      cmc += md[1].to_i
    end
    cmc += mana_cost.gsub(/[0-9X]/, '').size # Add however many symbols are left after stripping out numbers and X.
  end

  def transforms?
    ! transforms_into_id.nil?
  end

  def transforms_into
    Card.find transforms_into_id
  end

  def type_line
    str  = ""
    str += "#{supertypes.join} " unless self.supertypes.empty?
    str += "#{types.join}"
    str += " -- #{subtypes.join}" unless self.subtypes.empty?
  end

  def to_s
    str  = "#{name}\n"
    str += "#{mana_cost}\n" if self.mana_cost
    str += "#{type_line}\n"
    str += "#{text}\n"
  end

  def ascii_name
    # The Oracle text file is regular ASCII, so when making lookups from it we
    # need to convert Unicode card names into their bare ASCII equivalents.
    name.gsub("Æ", "AE").gsub("û", "u").gsub('é', 'e')
  end
end
