class Printing < ActiveRecord::Base
  attr_accessible :artist_id, :card_id, :expansion_id, :multiverse_id, :number, :rarity_id

  belongs_to :card
  belongs_to :expansion
  belongs_to :artist
  belongs_to :rarity

  def gatherer_image_url
    "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{multiverse_id}&type=card"
  end

  def image_path
    File.join(expansion.image_dir, "#{multiverse_id}.png")
  end
end
