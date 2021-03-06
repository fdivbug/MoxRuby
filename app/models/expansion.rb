require 'cgi'

class Expansion < ActiveRecord::Base
  attr_accessible :border, :name, :release_date, :code, :scg_name, :scg_number

  has_many :printings
  has_many :cards, :through => :printings

  def scg_url
    "http://sales.starcitygames.com/spoiler/display.php?s[#{scg_name}]=#{scg_number}&g[G1]=NM%2FM&foil=all&for=no&display=4&numpage=200&action=Show+Results"
  end

  def gatherer_url
    "http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&set=[%22#{CGI.escape(name)}%22]"
  end

  def image_dir
    File.join(Rails.root, "public", "images", "cards", code)
  end

  def image_url_dir
    "/images/cards/#{code}"
  end

  def border_image_path
    File.join(Rails.root, "public", "images", "cards", "border-#{border}.png")
  end
end
